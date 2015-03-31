module Bosh::Workspace
  module Schemas
    class Releases < Membrane::Schemas::Base
      def validate(object)
        Membrane::SchemaParser.parse do
          [{
            "name"          => String,
            "version"       => ReleaseVersion.new,
            optional("ref") => enum(String),
            optional("git") => String,
          }]
        end.validate object
      end
    end

    class ReleaseVersion < Membrane::Schemas::Base
      def validate(object)
        return if object == "latest"
        begin
          SemiSemantic::Version.parse(object.to_s)
        rescue SemiSemantic::ParseError
          raise Membrane::SchemaValidationError.new(
            "Should match: latest, Semantic versioning. Given: #{object}")
        end
      end
    end
  end
end
