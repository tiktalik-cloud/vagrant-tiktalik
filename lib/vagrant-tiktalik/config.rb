require "vagrant"

module VagrantPlugins
  module TiktalikVagrant
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :api_key
      attr_accessor :image
      attr_accessor :size
      attr_accessor :ssh_key
      attr_accessor :api_secret
      attr_accessor :ca_file
      attr_accessor :networks

      def initialize
        @api_key    = UNSET_VALUE
        @image      = UNSET_VALUE
        @size       = UNSET_VALUE
        @ssh_key    = UNSET_VALUE
        @api_secret = UNSET_VALUE
        @ca_file    = UNSET_VALUE
        @networks   = UNSET_VALUE
      end

      def finalize!
        @api_key    = ENV['TIKTALIK_API_KEY'] if @api_key == UNSET_VALUE
        @image      = nil if @image == UNSET_VALUE
        @size       = 0.5 if @size == UNSET_VALUE
        @ssh_key    = nil if @ssh_key == UNSET_VALUE
        @api_secret = ENV['TIKTALIK_API_SECRET'] if @api_secret == UNSET_VALUE
        @ca_file    = nil if @ca_file == UNSET_VALUE
        @networks   = nil if @networks == UNSET_VALUE
      end

      def validate(machine)
        errors = []

        errors << I18n.t("vagrant_tiktalik.config.api_key_required") if config.api_key.nil?
        errors << I18n.t("vagrant_tiktalik.config.api_secret_required") if config.api_secret.nil?
        errors << I18n.t("vagrant_tiktalik.config.image_required") if config.image.nil?
        errors << I18n.t("vagrant_tiktalik.config.ssh_key_required") if !@ssh_key

        # TODO validate network

        { "Tiktalik Provider" => errors }
      end
    end
  end
end
