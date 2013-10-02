require "log4r"
require 'time'

require "tiktalik"
#require "tiktalik/computing/instance"

module VagrantPlugins
  module TiktalikVagrant
    module Action
      # This action reads the state of the machine and puts it in the
      # `:machine_state_id` key in the environment.
      class ReadState
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_tiktalik::action::read_state")
          @config = env[:machine].provider_config
        end

        def call(env)
          t = Tiktalik
          t.api_key = @config.api_key
          t.api_secret_key = @config.api_secret

          env[:machine_state_id] = :not_created

          hostname = env[:machine].config.vm.hostname || env[:machine].name

          i = Tiktalik::Computing::Instance
          instances = i.all
          instances.each do |instance|
            if instance.hostname == hostname.to_s
              env[:machine].id = instance.uuid if env[:machine].id.nil?
              case instance.state
                when 12
                  if instance.running
                    env[:machine_state_id] = :running
                  else
                    env[:machine_state_id] = :stopped
                  end
                else
                  env[:machine_state_id] = :pending
              end
              break
            end
          end

          @app.call(env)
        end

        #def read_state(env)
        #  return :not_created if machine.id.nil?
        #
        #  # Find the machine
        #  server = aws.servers.get(machine.id)
        #  if server.nil? || [:"shutting-down", :terminated].include?(server.state.to_sym)
        #    # The machine can't be found
        #    @logger.info("Machine not found or terminated, assuming it got destroyed.")
        #    machine.id = nil
        #    return :not_created
        #  end
        #
        #  # Return the state
        #  return server.state.to_sym
        #end
      end
    end
  end
end
