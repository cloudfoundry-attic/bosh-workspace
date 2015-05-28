module Bosh::Workspace
  module Schemas
    class Networks < Membrane::Schemas::Base
      def validate(object)
        Membrane::SchemaParser.parse do
          [{
             "name" => String,
             "rename" => String,
             "static" => [String]
           }]
        end.validate object
      end
    end
  end
end
