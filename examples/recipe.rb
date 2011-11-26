#
# Cookbook Name:: cloud_foundry
# Recipe:: default
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

mongo_service = "mongodb-example"
cf_target = "api.vcap.me"
cf_admin = "andrea.campi@zephirworks.com"
cf_password = "password"
private_key = "-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEArXRT81rXuFo0Rawyy6tPvnLXsn9fqryNK3VwzZYXTMegJcWF\n....n-----END RSA PRIVATE KEY-----"

cloud_foundry_service mongo_service do
  target cf_target
  admin cf_admin
  admin_password cf_password

  service "mongodb"
  action :create
end

cloud_foundry_deploy "example" do
  repository "git@git:example.git"
  deploy_key private_key

  target cf_target
  admin cf_admin
  admin_password cf_password

  framework "rails3"
  runtime "ruby19"
  uris ["example.vcap.me"]
  instances 1
  mem_quota 256
  env ["c=d"]

  services [mongo_service]
end

# same repository, deployed under a different name
cloud_foundry_deploy "example2" do
  repository "git@git:example.git"
  deploy_key private_key

  target cf_target
  admin cf_admin
  admin_password cf_password

  framework "rails3"
  runtime "ruby19"
  uris ["example2.vcap.me"]
  instances 1
  mem_quota 256
  env ["c=d"]

  services [mongo_service]
end
