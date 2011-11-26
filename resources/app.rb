#
# Cookbook Name:: cloud_foundry
# Resource:: app
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

actions :login, :create, :upload, :start, :stop, :restart, :bind, :update

attribute :name, :kind_of => String, :name_attribute => true
attribute :target, :kind_of => String, :required => true
attribute :admin, :kind_of => String, :required => true
attribute :admin_password, :kind_of => String, :required => true
attribute :trace, :kind_of => [TrueClass, FalseClass]

# params to :create and :update
attribute :framework, :kind_of => String
attribute :runtime, :kind_of => String
attribute :uris, :kind_of => Array
attribute :instances, :kind_of => Integer
attribute :mem_quota, :kind_of => Integer
attribute :services, :kind_of => Array
attribute :env, :kind_of => Array

# params to :push
attribute :path, :kind_of => String
