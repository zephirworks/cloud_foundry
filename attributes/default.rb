#
# Cookbook Name:: cloud_foundry
# Attributes:: default
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

default[:cloud_foundry][:target] = "api.vcap.me"
default[:cloud_foundry][:trace] = false
default[:cloud_foundry][:mem_quota] = 256
default[:cloud_foundry][:cache_dir] = "/var/cache/chef/cf-git-checkout-cache"
