require "log4r"

require "tiktalik"

module VagrantPlugins
  module TiktalikVagrant
    module Action
      class PowerOn
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_tiktalik::action::power_on")
          @config = env[:machine].provider_config
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_tiktalik.powering_on"))

          t = Tiktalik
          t.api_key = @config.api_key
          t.api_secret_key = @config.api_secret
          t.ca_file = @config.ca_file

          i = Tiktalik::Computing::Instance
          instance = i.find env[:machine].id
          instance.start

          env[:machine].id = instance.uuid

          @app.call(env)
        end
      end
    end
  end
end
