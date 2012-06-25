#
# Cookbook Name:: hardware
# Recipe:: common
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

# All platforms get some kind of monitoring

include_recipe "monitoring"

%W{syslog cpu disk interface memory swap load}.each do |metric|
  monitoring_metric metric do
    type metric
  end
end
