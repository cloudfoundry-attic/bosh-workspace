module Bosh::Workspace
  module Schemas
    class Credentials < Membrane::Schemas::Base
      include Bosh::Workspace::GitProtocolHelper

      def validate(object)
        Membrane::SchemaParser.parse do
          [enum(UsernamePassword.new, SshKey.new)]
        end.validate object
        validate_protocol_credentials_combination(object)
      end

      def validate_protocol_credentials_combination(object)
        object.each do |creds|
          case git_protocol_from_url(creds['url'])
          when :https, :http
            next if creds.keys.include? 'username'
            validation_err "Provide username/password for: #{creds['url']}"
          when :ssh
            next if creds.keys.include? 'private_key'
            validation_err "Provide private_key for: #{creds['url']}"
          else
            validation_err "Credentials not supported for: #{creds['url']}"
          end
        end
      end

      def validation_err(message)
        raise Membrane::SchemaValidationError.new(message)
      end

      class UsernamePassword < Membrane::Schemas::Base
        def validate(object)
          Membrane::SchemaParser.parse do
            { "url" => String, "username" => String, "password" => String }
          end.validate object
        end
      end

      class SshKey < Membrane::Schemas::Base
        def validate(object)
          Membrane::SchemaParser.parse do
            { "url" => String, "private_key" => String }
          end.validate object
        end
      end
    end
  end
end
