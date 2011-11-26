#
# Cookbook Name:: cloud_foundry
# Recipe:: deploy
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

search(:apps) do |app|
  if app["server_roles"] & node.roles
    cf_target = app["target"]
    cf_admin = app["admin"]
    cf_password = app["admin_password"]

    app["services"].each_pair do |name,service_name|
      cloud_foundry_service name do
        target cf_target
        admin cf_admin
        admin_password cf_password

        service service_name
        action :create
      end
    end

    cloud_foundry_deploy app["name"] do
      repository app["repository"]

      target cf_target
      admin cf_admin
      admin_password cf_password

      framework app["framework"]
      runtime app["runtime"]
      uris app["uris"]
      instances app["instances"]
      mem_quota app["mem_quota"]
      env app["env"]

      services app["services"]
    end
  end
end
