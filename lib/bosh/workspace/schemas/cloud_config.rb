module Bosh::Workspace
  module Schemas
    class CloudConfig < Membrane::Schemas::Base
      def validate(object)
        Membrane::SchemaParser.parse do
          {
            "file"           => String,
            "networks"       => [{
              "name" => String,
              "rename" => String
            }]
          }
        end.validate object
      end
    end
  end
end
