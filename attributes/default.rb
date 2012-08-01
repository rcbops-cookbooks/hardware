default["hardware"]["install_oem"] = false

default["hardware"]["services"]["snmpd"]["network"] = "management"
default["hardware"]["services"]["snmpd"]["port"] = 161

default["hardware"]["snmpd"]["trap_server"] = "localhost"
default["hardware"]["snmpd"]["trap_community"] = "public"

default["hardware"]["snmpd"]["ro_community"] = "public"
default["hardware"]["snmpd"]["rw_community"] = nil
default["hardware"]["snmpd"]["syslocation"] = "Datacenter"
default["hardware"]["snmpd"]["syscontact"] = "sysadmin@example.com"
