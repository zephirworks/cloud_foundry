#
# Cookbook Name:: cloud_foundry
# Definition:: cloud_foundry_deploy
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

define :cloud_foundry_deploy do
  params[:target] ||= node[:cloud_foundry][:target]
  params[:trace] ||= node[:cloud_foundry][:trace]
  params[:mem_quota] ||= node[:cloud_foundry][:mem_quota]
  params[:enable_submodules] ||= false
  params[:cache_dir] ||= node[:cloud_foundry][:cache_dir]
  checkout_dir = "#{params[:cache_dir]}/#{params[:name]}"

  directory checkout_dir do
    action :create
    recursive true
  end

  cloud_foundry_app params[:name] do
    target params[:target]
    admin params[:admin]
    admin_password params[:admin_password]
    trace params[:trace]

    path checkout_dir

    framework params[:framework]
    runtime params[:runtime]
    uris params[:uris]
    instances params[:instances]
    mem_quota params[:mem_quota]
    env params[:env]

    services params[:services]

    action [:login, :update]
  end

  if params.has_key?(:deploy_key)
    ruby_block "write_key" do
      block do
        f = ::File.open("/tmp/id_deploy_#{params[:name]}", "w")
        f.print(params[:deploy_key])
        f.close
      end
      not_if do ::File.exists?("/tmp/id_deploy_#{params[:name]}"); end
    end

    file "/tmp/id_deploy_#{params[:name]}" do
      mode '0600'
    end

    template "/tmp/deploy-ssh-wrapper_#{params[:name]}" do
      cookbook "cloud_foundry"
      source "deploy-ssh-wrapper.erb"
      mode "0755"
      variables(:name => params[:name],
                :id_deploy => "/tmp/id_deploy_#{params[:name]}")
    end
  end

  git "checkout #{params[:name]}" do
    repository params[:repository]
    revision params[:revision]
    destination checkout_dir
    depth 5 # XXX
    ssh_wrapper "/tmp/deploy-ssh-wrapper_#{params[:name]}" if params.has_key?(:deploy_key)
    enable_submodules params[:enable_submodules]

    action :sync
    notifies :upload, resources(:cloud_foundry_app => params[:name])
  end
end
