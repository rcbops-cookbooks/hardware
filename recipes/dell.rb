#
# Cookbook Name:: hardware
# Recipe:: dell
#
# Copyright 2012, Rackspace US, Inc.
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

include_recipe "osops-utils"
include_recipe "monitoring"
platform_options = node["hardware"]["platform"]

snmp_endpoint = get_bind_endpoint("hardware", "snmpd")

case node["platform"]
when "redhat", "centos"
  yum_key "RPM-GPG-KEY-dell" do
    url "http://linux.dell.com/repo/hardware/latest/RPM-GPG-KEY-dell"
    action :add
    only_if { platform?(%w{redhat centos}) }
  end

  yum_key "RPM-GPG-KEY-libsmbios" do
    url "http://linux.dell.com/repo/hardware/latest/RPM-GPG-KEY-libsmbios"
    action :add
    only_if { platform?(%w{redhat centos}) }
  end
  
  yum_repository "dell-omsa-indep" do
    description "Dell OMSA repository - Hardware independent"
    mirrorlist true
    url "http://linux.dell.com/repo/hardware/latest/mirrors.cgi?osname=el6&basearch=$basearch&native=1&dellsysidpluginver=$dellsysidpluginver"
    key "RPM-GPG-KEY-dell"
    bootstrapurl "http://linux.dell.com/repo/hardware/latest/bootstrap.cgi"
    action :add
    only_if { platform?(%w{redhat centos}) }
  end
  
  yum_repository "dell-omsa-specific" do
    description "Dell OMSA repository - Hardware specific"
    mirrorlist true
    url "http://linux.dell.com/repo/hardware/latest/mirrors.cgi?osname=el6&basearch=$basearch&native=1&sys_ven_id=$sys_ven_id&sys_dev_id=$sys_dev_id&dellsysidpluginver=$dellsysidpluginver"
    key "RPM-GPG-KEY-dell"
    bootstrapurl "http://linux.dell.com/repo/hardware/latest/bootstrap.cgi"
    action :add
    only_if { platform?(%w{redhat centos}) }
  end
when "ubuntu"
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
end

platform_options["omsa_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

%W{dataeng dsm_om_connsvc snmpd}.each do |svc|
  service svc do
    supports :status => true, :restart => true
    action [ :enable, :start ]
  end
end

template "/etc/snmp/snmpd.conf" do
  source "snmpd.conf.erb"
  owner "root"
  group "root"
  mode "0600"
  variables("bind_address" => snmp_endpoint["host"],
            "bind_port" => snmp_endpoint["port"],
            "trap_server" => node["hardware"]["snmpd"]["trap_server"],
            "trap_community" => node["hardware"]["snmpd"]["trap_community"],
            "ro_community" => node["hardware"]["snmpd"]["ro_community"],
            "rw_community" => node["hardware"]["snmpd"]["rw_community"],
            "syslocation" => node["hardware"]["snmpd"]["syslocation"],
            "syscontact" => node["hardware"]["snmpd"]["syscontact"],
            "flavor" => "omsa"
            )
  notifies :restart, resources(:service => "snmpd"), :immediately
end

# FIXME: ohai plugin, probably?
ruby_block "check idrac version" do
  block do
    Chef::Log.error("In check idrac")
    if not false #node.has_key?("omsa")
      Chef::Log.error("Doing omreport")
      node.set["omsa"] = {}
      omreport = "/opt/dell/srvadmin/bin/omreport"

      node.set["omsa"]["drac"] = {}

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
            node.set["omsa"]["drac"][attr] = value[0]
          end
        end
      end
    end
  end
  action :create
end

# Oooks, this is yowch, and very tied to collectd.
# needs abstracted more, but then, the pyscript stuff isn't
# very abstracted anyway, so there ya go.

monitoring_metric "omsa" do
  type "pyscript"
  script "omsa_plugin.py"
  alarms("hardware.chassis.healthy" => {
           "Type_gauge" => {
             :data_source => "value" ,
             :failure_min => 1.0 }},
         "hardware.memory.healthy" => {
           "Type_gauge" => {
             :data_source => "value",
             :failure_min => 1.0 }},
         "hardware.disks.healthy" => {
           "Type_gauge" => {
             :data_source => "value",
             :failure_min => 1.0 }})
end
