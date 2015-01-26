module Bosh::Workspace
  module Schemas
    class Credentials < Membrane::Schemas::Base
      def validate(object)
        Membrane::SchemaParser.parse do
          [enum(UsernamePassword.new, SshKey.new)]
        end.validate object
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
