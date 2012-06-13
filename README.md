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

 * osops-utils: required to find interface to bind snmpd on (uses the tagged network "management")
 * collectd-graphite: to report health information to collectd, if configured
 * apt: to add the vendor apt repositories


Attributes
==========

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

Usage
=====

add "recipe[hardware::default] to your runlist.  Set appropriate node
overrides (probably at environment level).  Enjoy great success.
