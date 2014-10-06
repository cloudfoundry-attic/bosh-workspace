module Bosh::Workspace
  module Schemas
    class DeploymentPatch < Membrane::Schemas::Base
      def validate(object)
        Membrane::SchemaParser.parse do
          {
            "stemcells"               => Stemcells.new,
            "releases"                => Releases.new,
            optional("templates_ref") => String
          }
        end.validate object
      end
    end
  end
end
