require 'vmc'
require File.join(gem_root = Gem.loaded_specs['vmc'].full_gem_path, 'lib', 'cli')

module ZephirWorks
  module CloudFoundry
    module VMC
      class Apps < ::VMC::Cli::Command::Apps
        def initialize(target, token, client)
          @target_url = target
          @auth_token = token
          @client = client
          super(:noprompts => true)
        end
      end

      def vmc_client(target, admin, password, trace = nil)
        if @client
          if target == @target && admin == @admin && password == @password
            return @client
          else
            @client = nil
          end
        end

        client = ::VMC::Client.new(target)
        client.trace = trace if trace
        @token = client.login(admin, password)

        @target = target
        @admin = admin
        @password = password
        @client = client
      end

      def vmc_apps
        @vmc_apps ||= Apps.new(@target, @token, @client)
      end

      def vmc_apps_upload(app_name, dir)
        vmc_apps.send(:upload_app_bits, app_name, dir)
      end

      def vmc_apps_start(app_name)
        vmc_apps.start(app_name)
      end

      def vmc_apps_stop(app_name)
        vmc_apps.stop(app_name)
      end

      def vmc_apps_restart(app_name)
        vmc_apps.restart(app_name)
      end
    end
  end
end
