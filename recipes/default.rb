#
# Cookbook Name:: hardware
# Recipe:: default
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.  See the License for the specific language governing
# permissions and limitations under the License.
#

include_recipe "osops-utils"

if vendor = rcb_safe_deref(node, "dmi.bios.vendor")
  case vendor
    when /[Dd]ell/
    include_recipe "hardware::dell"
    # Installing the hp management tools is probably a disservice
    #
    # when /^[hH][pP]/
    # include_recipe "hardware::hp"
  end
end
