require "vagrant"

module VagrantPlugins
  module TiktalikVagrant
    module Errors
      class VagrantTiktalikError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_tiktalik.errors")
      end

      class FogError < VagrantTiktalikError
        error_key(:fog_error)
      end

      class InstanceReadyTimeout < VagrantTiktalikError
        error_key(:instance_ready_timeout)
      end

      class RsyncError < VagrantTiktalikError
        error_key(:rsync_error)
      end
    end
  end
end
