module Bosh::Workspace
  module Schemas
    class Releases < Membrane::Schemas::Base
      def validate(object)
        Membrane::SchemaParser.parse do
          [{
            "name"    => String,
            "version" => enum(Integer, "latest"),
            "git"     => String,
          }]
        end.validate object
      end
    end
  end
end
