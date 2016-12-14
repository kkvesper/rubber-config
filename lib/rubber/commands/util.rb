require 'date'

module Rubber
  module Commands

    class Obfuscation < Clamp::Command

      def self.subcommand_name
        "util:obfuscation"
      end

      def self.subcommand_description
        "Obfuscates rubber-secret.yml using encryption"
      end

      option ["-f", "--secretfile"],
             "SECRETFILE",
             "The rubber_secret file\n (default: <Rubber.config.rubber_secret>)"

      option ["-k", "--secretkey"],
             "SECRETKEY",
             "The rubber_secret_key\n (default: <Rubber.config.rubber_secret_key>)"

      option ["-d", "--decrypt"],
             :flag,
             "Decrypt and display the current rubber_secret"

      option ["-g", "--generate"],
             :flag,
             "Generate a key for rubber_secret_key"

      def execute
        require 'rubber/encryption'

        if generate?
          puts "Obfuscation key: " + Rubber::Encryption.generate_encrypt_key.inspect
          exit
        else
          signal_usage_error "Need to define a rubber_secret in rubber.yml" unless secretfile
          signal_usage_error "Need to define a rubber_secret_key in rubber.yml" unless secretkey
          signal_usage_error "The file pointed to by rubber_secret needs to exist" unless File.exist?(secretfile)
          data = IO.read(secretfile)

          if decrypt?
            puts Rubber::Encryption.decrypt(data, secretkey)
          else
            puts Rubber::Encryption.encrypt(data, secretkey)
          end
        end
      end
    end
  end
end
