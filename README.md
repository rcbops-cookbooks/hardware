Description
===========

Generic hardware monitoring cookbook.  Currently, this tries to target
Dell OMSA and HP Insight Manager to the extent that these vendors support
the targeted linux distributions.  YMMV, etc.

This will install collectd monitors for health checking based on the
vendor platform services (if collectd has been configured... i.e. if a
role exists for collectd-server) and/or snmp services for integrating
into a SNMP monitored environment.  There is some ability to influence
the snmp configuration, detailed below in the "Attributes" section.

NOTE: Currently, this targets only Dell on Ubuntu Precise.  Fedora
support for both Dell and HP will be forthcoming, and HP for Precise
as well once the Insight Manager repos are updated for Precise.

Requirements
============

Chef 0.10.0 or higher required (for Chef environment use).

Platforms
--------

 * CentOS >= 6.3
 * Ubuntu >= 12.04

Cookbooks
---------

The following cookbooks are dependencies:

 * apt: to add the vendor apt repositories
 * monitoring: used to establish some base metrics and alerting
 * osops-utils: required to find interface to bind snmpd on (uses the tagged network "management")


Attributes
==========

 * default["hardware"]["install_oem"] = false

Where the SNMP listener is can be controlled with the following attributes:

 * default["hardware"]["services"]["snmpd"]["network"] = "management"
 * default["hardware"]["services"]["snmpd"]["port"] = 161

Trap server can be specified with the following attributes:

 * default["hardware"]["snmpd"]["trap_server"] = "localhost"
 * default["hardware"]["snmpd"]["trap_community"] = "public"

In addition, external trap sink can be disabled by setting trap_server to nil.

Community settings can be specified with the following attributes:

 * default["hardware"]["snmpd"]["ro_community"] = "public"
 * default["hardware"]["snmpd"]["rw_community"] = nil

These are set up for v1/v2c.  No attempt is made to configure v3.

The following mib-2 system variables can also be assigned:

 * default["hardware"]["snmpd"]["syslocation"] = "Datacenter"
 * default["hardware"]["snmpd"]["syscontact"] = "sysadmin@example.com"

Hash of platform specific package/service names and options

 * default["hardware"]["platform"]

Usage
=====

add "recipe[hardware::default] to your runlist.  Set appropriate node
overrides (probably at environment level).  Enjoy great success.

License and Author
==================

Author:: Justin Shepherd (<justin.shepherd@rackspace.com>)  
Author:: Jason Cannavale (<jason.cannavale@rackspace.com>)  
Author:: Ron Pedde (<ron.pedde@rackspace.com>)  
Author:: Joseph Breu (<joseph.breu@rackspace.com>)  
Author:: William Kelly (<william.kelly@rackspace.com>)  
Author:: Darren Birkett (<darren.birkett@rackspace.co.uk>)  
Author:: Evan Callicoat (<evan.callicoat@rackspace.com>)  
Author:: Matt Thompson (<matt.thompson@rackspace.co.uk>)  

Copyright 2012, Rackspace US, Inc.  

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
