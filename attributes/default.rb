default["hardware"]["install_oem"] = false                                      # cluster_attribute

default["hardware"]["services"]["snmpd"]["network"] = "management"              # node_attribute
default["hardware"]["services"]["snmpd"]["port"] = 161                          # node_attribute

default["hardware"]["snmpd"]["trap_server"] = "localhost"                       # node_attribute
default["hardware"]["snmpd"]["trap_community"] = "public"                       # node_attribute

default["hardware"]["snmpd"]["ro_community"] = "public"                         # cluster_attribute
default["hardware"]["snmpd"]["rw_community"] = nil                              # cluster_attribute
default["hardware"]["snmpd"]["syslocation"] = "Datacenter"                      # cluster_attribute
default["hardware"]["snmpd"]["syscontact"] = "sysadmin@example.com"             # cluster_attribute

case platform
when "redhat", "centos"
  default["hardware"]["platform"] = {                                           # node_attribute
    "omsa_packages" => ["srvadmin-all", "lm_sensors", "net-snmp",
                        "net-snmp-utils", "libsmi"]
  }
when "ubuntu"
  default["hardware"]["platform"] = {                                           # node_attribute
    "omsa_packages" => ["srvadmin-all", "lm-sensors", "snmp-mibs-downloader",
                        " snmpd"]
  }
end
