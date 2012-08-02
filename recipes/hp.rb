#
# Cookbook Name:: hardware
# Recipe:: hp
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

# This doesn't actually install HP monitoring software.  Instead, it
# installs a bunch of statically linked blobs that mostly just
# generate segfaults.
#
# Probably you don't want to actually use this.
#

include_recipe "apt"
include_recipe "osops-utils"

snmp_endpoint = get_bind_endpoint("hardware", "snmpd")

# this is kind of... wrong.  What a strange repo.
apt_repository "hp" do
  uri "http://downloads.linux.hp.com/SDR/downloads/ProLiantSupportPack/ubuntu"
  distribution "natty/8.70"  # closest we have... worth a try.
  components ["non-free"]

  notifies :run, resources(:execute => "apt-get update"), :immediately
end

# It would be way more useful if the package manifest actually contained
# all the packages in the package repo... so it goes.
bash "workaround-busted-hp-repo" do
  cwd "/tmp"
  user "root"
  code <<-EOF
    set -e
    tmpdir=$(mktemp -d)
    wget http://downloads.linux.hp.com/SDR/downloads/ProLiantSupportPack/ubuntu/pool/non-free/hpsmh_6.0.0-97_amd64.deb -O ${tmpdir}/hpsmh.deb

    if [ -e ${tmpdir}/hpsmh.deb ]; then
        dpkg -i ${tmpdir}/hpsmh.deb
        apt-get install -f
    fi

    rm -rf ${tmpdir}
    EOF

  not_if "dpkg -l hpsmh"
end


%W{snmpd hponcfg hpacucli cpqacuxe hp-smh-templates hp-health hp-snmp-agents}.each do |pkg|
  package pkg do
    action :install
    # unsigned repo.  :(
    options "--force-yes"
  end
end

%W{snmpd hp-asrd hp-health hpsmhd hp-snmp-agents}.each do |svc|
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
            "flavor" => "hp"
            )
  notifies :restart, resources(:service => "snmpd"), :immediately
end

management_interface = get_if_for_net("management")

template "/opt/hp/hp-snmp-agents/cma.conf" do
  source "cma.conf.erb"
  mode "0644"
  owner "root"
  group "root"

  variables("snmp_interface" => management_interface,
            "snmp_trap_interface" => management_interface
            )

  notifies :restart, resources(:service => "hp-snmp-agents")
end
