#
# Cookbook Name:: hardware_test
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

require_relative "./support/helpers"

describe_recipe "hardware_test::common" do
  include HardwareTestHelpers

  let(:plugin_dir) { "/etc/collectd/plugins" }
  let(:threshhold_dir) { "/etc/collectd/thresholds" }

  it "creates a metric for syslog" do
    config = file(::File.join(plugin_dir, "syslog.conf"))
    config.must_exist
    config.must_include 'LoadPlugin "syslog"'
  end

  it "creates a metric for syslog" do
    config = file(::File.join(plugin_dir, "cpu.conf"))
    config.must_exist
    config.must_include 'LoadPlugin "cpu"'
  end

  it "creates a metric for memory" do
    config = file(::File.join(plugin_dir, "memory.conf"))
    config.must_exist
    config.must_include 'LoadPlugin "memory"'
  end

  it "creates a metric for swap" do
    config = file(::File.join(plugin_dir, "swap.conf"))
    config.must_exist
    config.must_include 'LoadPlugin "swap"'
  end

  it "creates a metric for load" do
    config = file(::File.join(plugin_dir, "swap.conf"))
    config.must_exist
    config.must_include 'LoadPlugin "swap"'
  end

  it "creates an alert for load" do
    threshhold = file(::File.join(threshhold_dir, "load.conf"))
    threshhold.must_exist
    threshhold.must_include "WarningMax #{node["cpu"]["total"] * 2}"
  end

  it "creates 80 usage, and 95% alarm for mounted file systems" do
    unmonitored_fs =
      %w(proc sysfs fusectl debugfs securityfs devtmpfs devpts tmpfs xenfs)

    mounts = node["filesystem"].inject({}) do |hash, (k, v)|
      if v.has_key?("mount") and v.has_key?("fs_type") and
        not unmonitored_fs.include?(v["fs_type"]) and v.has_key?("kb_size") then

        hash.merge(v["mount"] => 1024 * v["kb_size"].to_i)
      else
        hash
      end
    end

    mounts.each_pair do |mount, size|
      mount = mount.gsub(/^\//, "")
      mount = "root" if mount == ""
      mount = mount.gsub("/", "-")

      warning_val = 0.8 * size
      alarm_val = [0.95 * size, size - (4096 * 1024 * 1024 * 1024)].max

      threshhold = file(::File.join(threshhold_dir, "#{mount}.conf"))
      threshhold.must_exist
      threshhold.must_include "Instance \"#{mount}\""
      threshhold.must_include "WarningMax #{warning_val}"
      threshhold.must_include "FailureMax #{alarm_val}"
    end
  end

  it "creates > 1500 write ops/sec paging alter for swaps" do
    swaps = node["filesystem"].inject([]) do |ary, (k, v)|
      if v.has_key?("fs_type") and v["fs_type"] == "swap"
        ary << k.split("/").last
      else
        ary
      end
    end

    swaps.each do |swap|
      threshhold = file(::File.join(threshhold_dir, "disk-#{swap}.conf"))
      threshhold.must_exist
      threshhold.must_include "Instance \"#{swap}\""
      threshhold.must_include "WarningMax 1500.0"
    end
  end

  it "creates 80% bandwidth thresholds on networks" do
    networks = node["network"]["interfaces"].inject([]) do |ary, (k, v)|
      if v.has_key?("encapsulation") and v["encapsulation"] == "Ethernet"
        ary << k
      else
        ary
      end
    end

    networks.each do |network|
      ["rx", "tx"].each do |io|
        threshhold =
          file(::File.join(threshhold_dir, "network-#{network}-#{io}.conf"))
        threshhold.must_exist
        threshhold.must_include 'Plugin "interface"'
        threshhold.must_include "WarningMax 83886080.0"
      end
    end
  end
end
