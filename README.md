DESCRIPTION
===========

A Chef cookbook to manage applications and services on
[Cloud Foundry](http://www.cloudfoundry.org/).
It is designed to be compatible with any installation of CloudFoundry, whether
[hosted](http://www.cloudfoundry.com/), self-hosted or based on 
[Micro Cloud Foundry](https://www.cloudfoundry.com/micro).

This cookbook provides:

* a `cloud_foundry_app` LWRP you can use to create, update and delete application
instances; bind apps to services; and start, stop and restart instances;
* a `cloud_foundry_service` LWRP that lets you create services (and more in the future);
* a `cloud_foundry_deploy` definition that enables you to continuously deploy an
application from a git repository, in a similar way to the standard `deploy_revision`
resource.

REQUIREMENTS
============

The cloud\_foundry cookbook requires the `vmc` gem; the `cloud_foundry::default`
recipe will install it automatically.

Cloud Foundry is a Platform as a Service (PaaS) solution; as such, chances are
you can't or won't run chef-client on your CF instance. This cookbook assumes
you will use a separated, trusted host as a controller for your CF cloud.

Security best practice
----------------------

The cloud\_foundry cookbook will needs valid credentials to your CF cloud, and
the underlying `VMC` gem will save access tokens locally. You should take
appropriate measures to ensure this host is not compromised. It is highly
recommended that you use a dedicate CF account for this purpose and that you
use a dedicated server (a basic virtual machine will suffice) that is running
no other services accessible from outside your trusted network.

ATTRIBUTES
==========

USAGE
=====

This document assumes you are already somewhat familiar with CF and its core
concepts; if you are not, you should start by reading up on CF at
[Cloud Foundry](http://www.cloudfoundry.org/).

cloud\_foundry\_app
-------------------

The `cloud_foundry_app` resource requires the following attributes:

* _target_ the URL to the CF instance;
* _admin_ the login to use when connecting to CF;
* _admin\_password_ the password to use when connecting to CF.

For example, this is how you log in to CF:

    cloud_foundry_app "test" do
      target "http://api.vcap.me"
      admin "chef@example.com"
      admin_password "chefpassword"
      action :login
    end

To help debug any issue with CF (or with the cookbook), you can optionally
set the _target_ attribute to true.

The `cloud_foundry_app` resource understand the following actions:

* _login_ lets you log in to CF. Credentials are cached for subsequent
actions, until another login is performed;
* _create_ creates a new application, unless it already exists, in which
case it silently does nothing. The _create_ action takes a few attributes:
  * _framework_ one of the frameworks supported by your CF instance. Run
  `vmc frameworks` for a list of the possible values;
  * _runtime_ one of the runtimes supported by your CF instance; you can
  find all of them by running `vmc runtimes`;
  * _uris_ an array of URLs this app should reply to;
  * _instances_ the number of instances to start; optional, it defaults to 1;
  * _mem\_quota_ the amount of RAM to reserve for this app; optional, it
  defaults to 256MB.
* _bind_ binds one or more services to an app. The services are specified with
a _services_ attribute that takes an array of service aliases (you can get a
list by running services). Note that any service bound to the app but not
present in the array will be unbound;
* _update_ updates attributes for an existing app, or creates it if it doesn't
exist yet; it also binds services to the app. It takes the same attribute as
_create_ and _bind_;
* _upload_ uploads new and updated code for an existing application, created
with the _create_ action. You must set the _path_ attribute to the absolute
path to a directory containing your application;
* _start_, _stop_ and _restart_ do what you would expect;

As usual with Chef, you can combine actions together to perform more complex
operations at the same time. For instance, you can replicate what `vmc push`
does with this resource:

    cloud_foundry_app "hello_world" do
      target "http://api.vcap.me"
      admin "chef@example.com"
      admin_password "chefpassword"

      framework "sinatra"
      runtime "ruby19"
      uris [ "helloworld.vcap.me", "helloworld.example.com" ]
      instances 42

      path "/tmp/helloworld"

      action :create:, :upload
    end

cloud\_foundry\_service
-----------------------

The `cloud_foundry_service` resource requires the following attributes:

* _target_ the URL to the CF instance;
* _admin_ the login to use when connecting to CF;
* _admin\_password_ the password to use when connecting to CF.

The `cloud_foundry_service` resource implements the following actions:

* _create_ provisions a service; you specify the type of service with the
_service_ attribute. See `vmc services` for a list of permissible service
names.

cloud\_foundry\_deploy
----------------------

The `cloud_foundry_deploy` definition builds upon the _cloud\_foundry_ LWRPs
to provide a drop-in replacement for _deploy\_revision_ to deploy an app to CF.

It takes the same attributes as the _:update_ and _:upload_ actions of the
`cloud_foundry_app` resource, and a few extra attributes:

* _repository_ the URL to the git repository containing the app;
* _revision_ the git "ref" to deploy (it can the name of a branch, a tag or the
SHA-1 of a commit);
* _enable\_submodules_ if true, git submodules will be updated after `git clone` or
`git update` is done;
* _deploy\_key_ a private key to use when doing git over SSH.

See _examples/deploy.rb_ for a real-world example of using `cloud\_foundry\_deploy`
together with a data bag to perform continuous deployment of a set of apps.
