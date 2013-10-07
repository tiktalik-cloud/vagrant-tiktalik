require "log4r"

module VagrantPlugins
  module TiktalikVagrant
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_tiktalik::action::read_ssh_info")
          @config = env[:machine].provider_config
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env[:machine])

          @app.call(env)
        end

        def read_ssh_info(machine)
          return nil if machine.id.nil?

          t = Tiktalik
          t.api_key = @config.api_key
          t.api_secret_key = @config.api_secret
          t.ca_file = @config.ca_file

          i = Tiktalik::Computing::Instance
          instance = i.find machine.id

          if instance.nil?
            # The machine can't be found
            @logger.info("Machine couldn't be found, assuming it got destroyed.")
            machine.id = nil
            return nil
          end

          ip = nil
          instance.interfaces.each do |iface|
            ip = iface.ip if iface.network.public == true
          end

          # Read the DNS info
          return {
            :host => ip,
            :port => 22,
            :username => "root"
          }
        end
      end
    end
  end
end
