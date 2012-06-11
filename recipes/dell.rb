#
# Cookbook Name:: hardware
# Recipe:: dell
#
# Copyright 2012, Rackspace Hosting
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

# Recipes to install Dell-specific hardware monitoring software

include_recipe "apt"

# this is kind of... wrong.  What a strange repo.
apt_repository "dell" do
  uri "http://linux.dell.com/repo/community/deb/OMSA_7.0"
  distribution ""
  components ["/"]
  keyserver "pool.sks-keyservers.net"
  key "1285491434D8786F"

  notifies :run, resources(:execute => "apt-get update"), :immediately
end

%W{srvadmin-all lm-sensors snmp-mibs-downloader}.each do |pkg|
  package pkg do
    action :install
  end
end

%W{dataeng dsm_om_connsvc}.each do |svc|
  service svc do
    supports :status => true, :restart => true
    action [ :enable, :start ]
  end
end

# FIXME: ohai plugin, probably?
ruby_block "check idrac version" do
  block do
    Chef::Log.error("In check idrac")
    if not false #node.has_key?("omsa")
      Chef::Log.error("Doing omreport")
      node["omsa"] = {}
      omreport = "/opt/dell/srvadmin/bin/omreport"

      node["omsa"]["drac"] = {}

      drac_values = {
        "device" => /^Device Type/,
        "guid" => /^System GUID/,
        "ipmi_enabled" => /^Enable IPMI/,
        "mac" => /^MAC Address/,
        "address" => /^IP Address/,
        "subnet" => /^IP Subnet/,
        "gateway" => /^IP Gateway/
      }

      IO.popen("#{omreport} chassis remoteaccess").readlines.each do |line|
        key, *value = line.split(":",2)
        drac_values.each_pair do |attr, regex|
          if key =~ regex
            node["omsa"]["drac"][attr] = value[0]
          end
        end
      end
    end
  end
  action :create
end


if get_settings_by_role("collectd-server", "roles")
  include_recipe "hardware::dell-monitoring"
end
