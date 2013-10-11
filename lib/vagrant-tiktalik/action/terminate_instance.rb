require "log4r"
require "time"

require "tiktalik"

module VagrantPlugins
  module TiktalikVagrant
    module Action
      # This terminates the running instance.
      class TerminateInstance
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_tiktalik::action::terminate_instance")
          @config = env[:machine].provider_config
        end

        def call(env)
          # Destroy the server and remove the tracking ID
          env[:ui].info(I18n.t("vagrant_tiktalik.terminating"))

          t = Tiktalik
          t.api_key = @config.api_key
          t.api_secret_key = @config.api_secret
          t.ca_file = @config.ca_file

          i = Tiktalik::Computing::Instance
          instance = i.find env[:machine].id
          instance.destroy

          env[:machine].id = nil

          @app.call(env)
        end
      end
    end
  end
end
