#
# Cookbook Name:: cloud_foundry
# Provider:: service
#
# Copyright 2011, ZephirWorks
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

include ZephirWorks::CloudFoundry::VMC

action :create do
  unless new_resource.service
    raise "cloud_foundry: you must specify a service"
  end
  unless exists?
    Chef::Log.info "cloud_foundry: Creating service #{new_resource.name}"

    client.create_service(new_resource.service, new_resource.name)

    new_resource.updated_by_last_action(true)
  end
end

def load_current_resource
  VMC::Cli::Config.output = STDOUT  # XXX

  @current_resource = Chef::Resource::CloudFoundryService.new(@new_resource.name)
  @current_resource.target(@new_resource.target)
  @current_resource.admin(@new_resource.admin)
  @current_resource.admin_password(@new_resource.admin_password)
  @current_resource.trace(@new_resource.trace)

  @current_resource
end

private
def client
  @vmc ||= vmc_client(@new_resource.target, @new_resource.admin, @new_resource.admin_password, @new_resource.trace)
end

def exists?
  @services ||= client.services
  @services.any? { |s| s[:name] == new_resource.name }
end
