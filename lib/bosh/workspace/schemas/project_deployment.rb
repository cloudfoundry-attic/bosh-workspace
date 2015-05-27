module Bosh::Workspace
  module Schemas
    class ProjectDeployment < Membrane::Schemas::Base
      UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

      def validate(object)
        Membrane::SchemaParser.parse do
          {
            "name"                  => String,
            "director_uuid"         => enum(UUID_REGEX, "current"),
            optional("domain_name") => String,
            optional("cloud_config")=> CloudConfig.new,
            "releases"              => Releases.new,
            "stemcells"             => Stemcells.new,
            "templates"             => [String],
            "meta"                  => Hash
          }
        end.validate object
      end
    end
  end
end
