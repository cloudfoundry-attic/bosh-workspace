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
            "releases"              => Releases.new,
            "stemcells"             => Stemcells.new,
            "templates"             => [String],
            "meta"                  => Hash,
            optional("merge_tool")  => MergeTool.new
          }
        end.validate object
      end

      class MergeTool < Membrane::Schemas::Base
        def validate(object)
          return if object.is_a? String
          return if object.is_a? Hash &&
                    (%w(name version) & object.keys).size == 2 &&
                    object['version'] =~ /^\d+(\.\d+){1,2}|current$/
          raise Membrane::SchemaValidationError.new(
            "Should match: String, object.name and object.version. Given: #{object}")
        end
      end

    end
  end
end
