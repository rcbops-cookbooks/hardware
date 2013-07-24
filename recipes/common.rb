#
# Cookbook Name:: hardware
# Recipe:: common
#
# Copyright 2012-2013, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "monitoring"

monitoring_metric "syslog" do
  type "syslog"
end

monitoring_metric "cpu" do
  type "cpu"
end

monitoring_metric "memory" do
  type "memory"
end

monitoring_metric "swap" do
  type "swap"
end

# base load alerts -- loadavg 5 > 2 x logical procs
monitoring_metric "load" do
  type "load"
  warning_max((node["cpu"]["total"] * 2).to_s)
end

# TODO:(claco) move to attributes so we can ignore other things
unmonitored_fs =
  %w(proc sysfs fusectl debugfs securityfs devtmpfs devpts tmpfs xenfs)

# TODO:(claco) Push these crazy finders up into osops-utils libraries
#
# set up base disk utilization -- warn at 80% used for all mounted partitions
# alarm at 95%, or 4G, whichever is higher
node["filesystem"].inject({}) do |hash, (k, v)|
  if v.has_key?("mount") and v.has_key?("fs_type") and
    not unmonitored_fs.include?(v["fs_type"]) and v.has_key?("kb_size") then

    hash.merge(v["mount"] => 1024 * v["kb_size"].to_i)
  else
    hash
  end
end.each_pair do |key, value|
  warning_val = 0.8 * value
  alarm_val = [0.95 * value, value - (4096 * 1024 * 1024 * 1024)].max

  monitoring_metric key do
    type "df"
    ignore_fs unmonitored_fs
    mountpoint key
    warning_max warning_val.to_s
    failure_max alarm_val.to_s
  end
end

# base alert for high paging -- find the swap disk (if it exists)
# and set up warnings for > 1500 write ops/sec - indicative of high
# paging activity
node["filesystem"].inject([]) do |ary, (k, v)|
  if v.has_key?("fs_type") and v["fs_type"] == "swap"
    ary << k.split("/").last
  else
    ary
  end
end.each do |swapdev|
  monitoring_metric "disk-#{swapdev}" do
    type "disk"
    device swapdev
    warning_max "1500"
  end
end

# set up thresholds for 80% total bandwidth.  Sadly, I don't know
# if this is pre-differentiated
node["network"]["interfaces"].inject([]) do |ary, (k, v)|
  if v.has_key?("encapsulation") and v["encapsulation"] == "Ethernet"
    ary << k
  else
    ary
  end
end.each do |netdev|
  monitoring_metric "network-#{netdev}" do
    type "interface"
    interface netdev
    warning_max((80 * 1024 * 1024).to_s)
  end
end
