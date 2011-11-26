#
# Cookbook Name:: cloud_foundry
# Provider:: app
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

action :login do
  client
  vmc_apps
end

action :create do
  unless exists?
    Chef::Log.info "cloud_foundry: Creating app #{new_resource.name}"

    manifest = {
      :name => "#{new_resource.name}",
      :staging => {
         :framework => new_resource.framework,
         :runtime => new_resource.runtime
      },
      :uris => new_resource.uris,
      :instances => new_resource.instances || 1,
      :resources => {
        :memory => new_resource.mem_quota || 256
      }
    }

    client.create_app(new_resource.name, manifest)

    new_resource.updated_by_last_action(true)
  end
end

action :upload do
  unless new_resource.path
    raise "cloud_foundry: you must specify a path"
  end
  unless exists?
    raise "cloud_foundry: app #{new_resource.name} does not exist"
  end

  Chef::Log.info "cloud_foundry: Uploading app #{new_resource.name}"
  vmc_apps_upload(new_resource.name, new_resource.path)
  new_resource.updated_by_last_action(true)

  action_restart
end

action :start do
  unless exists?
    raise "cloud_foundry: app #{new_resource.name} does not exist"
  end

  if running?
    Chef::Log.info "cloud_foundry: app #{new_resource.name} is already running"
  else
    Chef::Log.info "cloud_foundry: Starting app #{new_resource.name}"
    vmc_apps_start(new_resource.name)
    new_resource.updated_by_last_action(true)
  end
end

action :stop do
  unless exists?
    raise "cloud_foundry: app #{new_resource.name} does not exist"
  end

  if stopped?
    Chef::Log.info "cloud_foundry: app #{new_resource.name} is already stopped"
  else
    Chef::Log.info "cloud_foundry: Stopping app #{new_resource.name}"
    vmc_apps_stop(new_resource.name)
    new_resource.updated_by_last_action(true)
  end
end

action :restart do
  unless exists?
    raise "cloud_foundry: app #{new_resource.name} does not exist"
  end

  Chef::Log.info "cloud_foundry: Restarting app #{new_resource.name}"
  vmc_apps_restart(new_resource.name)
  new_resource.updated_by_last_action(true)
end

action :bind do
  unless exists?
    raise "cloud_foundry: app #{new_resource.name} does not exist"
  end

  Chef::Log.info "cloud_foundry: Binding services #{new_resource.services} to app #{new_resource.name}"
  app_info ||= client.app_info(new_resource.name)
  run_bind(app_info, new_resource.services)
end

action :update do
  unless exists?
    Chef::Log.info "cloud_foundry: App #{new_resource.name} does not exist, running :create"
    action_create
  else
    run_update
  end
end

def load_current_resource
  @current_resource = Chef::Resource::CloudFoundryApp.new(@new_resource.name)
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
  if @app_info
    true
  else
    @app_info = client.app_info(new_resource.name)
    @app_info != nil
  end
rescue VMC::Client::NotFound
  false
end

def running?
  @app_info ||= client.app_info(new_resource.name)
  @app_info[:state] == "RUNNING"
end

def stopped?
  @app_info ||= client.app_info(new_resource.name)
  @app_info[:state] == "STOPPED"
end

def run_update
  @app_info ||= client.app_info(new_resource.name)
  new_info = info = @app_info
  needs_update = false

  if info[:staging][:model] != @new_resource.framework
    raise "cloud_foundry: App #{new_resource.name}, framework does not match: #{info[:staging][:model]} != #{@new_resource.framework}"
  end
  if info[:staging][:stack] != @new_resource.runtime
    raise "cloud_foundry: App #{new_resource.name}, runtime does not match: #{info[:staging][:stack]} != #{@new_resource.runtime}"
  end

  if info[:uris].sort != @new_resource.uris.sort
    Chef::Log.info "cloud_foundry: App #{new_resource.name} needs update: #{info[:uris].inspect} != #{@new_resource.uris.inspect}"
    needs_update = true
    new_info[:uris] = @new_resource.uris
  end

  if info[:instances] != @new_resource.instances
    Chef::Log.info "cloud_foundry: App #{new_resource.name} needs update: #{info[:instances]} != #{@new_resource.instances}"
    needs_update = true
    new_info[:instances] = @new_resource.instances
  end

  if info[:resources][:memory] != @new_resource.mem_quota
    Chef::Log.info "cloud_foundry: App #{new_resource.name} needs update: #{info[:resources].inspect} != #{@new_resource.mem_quota}"
    needs_update = true
    new_info[:resources][:memory] = @new_resource.mem_quota
  end

  if info[:services].sort != @new_resource.services.sort
    Chef::Log.info "cloud_foundry: App #{new_resource.name} needs update: #{info[:services].inspect} != #{@new_resource.services.inspect}"

    old_services = info[:services] - @new_resource.services
    Chef::Log.info "cloud_foundry: App #{new_resource.name} remove services #{old_services.inspect}"
    # run_unbind(info, old_services)

    new_services = @new_resource.services - info[:services]
    Chef::Log.info "cloud_foundry: App #{new_resource.name} adding services #{new_services.inspect}"
    run_bind(info, new_services)
  end

  if info[:env].sort != @new_resource.env.sort
    Chef::Log.info "cloud_foundry: App #{new_resource.name} needs update: #{info[:env].inspect} != #{@new_resource.env.inspect}"
    needs_update = true
    new_info[:env] = @new_resource.env
  end

  if needs_update
    client.update_app(@new_resource.name, new_info)
    new_resource.updated_by_last_action(true)
  end
end

def run_bind(app_info, services)
  services.each do |service|
    unless app_info[:services].include?(service)
      client.bind_service(service, new_resource.name)
      new_resource.updated_by_last_action(true)
    end
  end
end
