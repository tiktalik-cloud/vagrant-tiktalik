require "log4r"
require 'vagrant/util/retryable'
require 'vagrant-tiktalik/util/timer'

module VagrantPlugins
  module TiktalikVagrant
    module Action
      # This runs the configured instance.
      class RunInstance
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_tiktalik::action::run_instance")
          @config = env[:machine].provider_config
        end

        def call(env)
          image = @config.image
          hostname = env[:machine].config.vm.hostname || env[:machine].name
          size = @config.size
          ssh_key = @config.ssh_key

          # If there is no keypair then warn the user
          #if !keypair
          #  env[:ui].warn(I18n.t("vagrant_tiktalik.launch_no_keypair"))
          #end

          # If there is a subnet ID then warn the user
          #if subnet_id
          #  env[:ui].warn(I18n.t("vagrant_tiktalik.launch_vpc_warning"))
          #end

          # Launch!
          env[:ui].info(I18n.t("vagrant_tiktalik.launching_instance"))
          env[:ui].info(" -- Image: #{image}")
          env[:ui].info(" -- Hostname: #{hostname}")
          env[:ui].info(" -- Size: #{size}")
          env[:ui].info(" -- SSH key: #{ssh_key}")

          #env[:ui].info(" -- Security Groups: #{security_groups.inspect}") if !security_groups.empty?

          t = Tiktalik
          t.api_key = @config.api_key
          t.api_secret_key = @config.api_secret
          t.ca_file = @config.ca_file

          begin
            networks = []

            n = Tiktalik::Computing::Network
            n.all.each do |network|
              uuid = network.uuid.to_s
              name = network.name.to_s
              if @config.networks
                (networks.push uuid) if
                  @config.networks.include?(uuid) or
                  @config.networks.include?(name)
              else
                (networks.push uuid) if network.public
                break if network.public
              end
            end

            env[:ui].info(" -- Networks: #{networks}")

            options = {
              :image_uuid => image,
              :hostname => hostname,
              :size => size,
              :"networks[]" => networks,
              :ssh_key => ssh_key
            }

            #if !security_groups.empty?
            #  security_group_key = options[:subnet_id].nil? ? :groups : :security_group_ids
            #  options[security_group_key] = security_groups
            #end

            i = Tiktalik::Computing::Instance
            instance = i.create options
          rescue Exception => e
            raise e
          #  # Invalid subnet doesn't have its own error so we catch and
          #  # check the error message here.
          #  if e.message =~ /subnet ID/
          #    raise Errors::FogError,
          #      :message => "Subnet ID not found: #{subnet_id}"
          #  end
          #
          #  raise
          #rescue Fog::Compute::TiktalikVagrant::Error => e
          #  raise Errors::FogError, :message => e.message
          end

          ## Immediately save the ID since it is created at this point.
          env[:machine].id = instance.uuid

          env[:ui].info(I18n.t("vagrant_tiktalik.waiting_for_ready"))

          ## Wait for the instance to be ready first
          retryable(:tries => 120, :sleep => 10) do
            next if env[:interrupted]
            result = i.find instance.uuid
            yield result if block_given?
            raise 'not ready' if result.state != 12 || !result.running
          end

          env[:ui].info(I18n.t("vagrant_tiktalik.waiting_for_ssh"))

          # waiting for ssh to start up and server ssh keys to generate
          retryable(:tries => 120, :sleep => 10) do
            next if env[:interrupted]
            raise 'not ready' if !env[:machine].communicate.ready?
          end

          # Ready and booted!
          env[:ui].info(I18n.t("vagrant_tiktalik.ready"))

          @app.call(env)
        end

        def recover(env)
          return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

          if env[:machine].provider.state.id != :not_created
            # Undo the import
            terminate(env)
          end
        end

        def terminate(env)
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Action.action_destroy, destroy_env)
        end
      end
    end
  end
end
