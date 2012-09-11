default["hardware"]["install_oem"] = false

default["hardware"]["services"]["snmpd"]["network"] = "management"
default["hardware"]["services"]["snmpd"]["port"] = 161

default["hardware"]["snmpd"]["trap_server"] = "localhost"
default["hardware"]["snmpd"]["trap_community"] = "public"

default["hardware"]["snmpd"]["ro_community"] = "public"
default["hardware"]["snmpd"]["rw_community"] = nil
default["hardware"]["snmpd"]["syslocation"] = "Datacenter"
default["hardware"]["snmpd"]["syscontact"] = "sysadmin@example.com"

case platform
when "redhat", "centos"
  default["hardware"]["platform"] = {
    "omsa_packages" => ["srvadmin-all", "lm_sensors", "net-snmp",
                        "net-snmp-utils", "libsmi"]
  }
when "ubuntu"
  default["hardware"]["platform"] = {
    "omsa_packages" => ["srvadmin-all", "lm-sensors", "snmp-mibs-downloader",
                        " snmpd"]
  }
end
