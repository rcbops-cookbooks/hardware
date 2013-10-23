name             "hardware"
maintainer       "Rackspace US, Inc."
maintainer_email "rcb-deploy@lists.rackspace.com"
license          "Apache 2.0"
description      "Installs/Configures hardware"
long_description IO.read(File.join(File.dirname(__FILE__), "README.md"))
version          IO.read(File.join(File.dirname(__FILE__), 'VERSION'))


%w{ amazon centos debian fedora oracle redhat scientific ubuntu }.each do |os|
  supports os
end

%w{ monitoring }.each do |dep|
  depends dep
end

recipe "hardware::default",
  "Installs various monitonoring/metrics common to all supported hardware"

recipe "hardware::common",
  "Installs various monitonoring/metrics common to all supported hardware"
