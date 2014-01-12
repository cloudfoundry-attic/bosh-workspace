module Bosh::Manifests
  class Manifest
    include Bosh::Cli::Validation
    attr_reader :name, :templates, :director_uuid, :meta

    def initialize(file)
      @file = file
    end

    def perform_validation(options = {})
      manifest_yaml = File.read(@file)
      m = Psych.load(manifest_yaml)

      if m.is_a?(Hash)
        unless m.has_key?("name") && m["name"].is_a?(String)
          errors << "Manifest should contain a name"
        end

        unless m.has_key?("templates") && m["templates"].is_a?(Array)
          errors << "Manifest should contain templates"
        end

        unless m.has_key?("director_uuid") && m["director_uuid"].is_a?(String)
          errors << "Manifest should contain a director_uuid"
        end

        unless m.has_key?("meta") && m["meta"].is_a?(Hash)
          errors << "Manifest should contain meta hash"
        end
        setup_manifest_attributes(m)
      else
        errors << "Manifest should be a hash"
      end
    end

    def filename
      File.basename(@file)
    end

    private

    def setup_manifest_attributes(manifest)
      @name = manifest["name"]
      @templates = manifest["templates"]
      @meta = manifest["meta"]
      @director_uuid = manifest["director_uuid"]
    end
  end
end
