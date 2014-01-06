module Bosh::Manifests
  class Manifest
    include Bosh::Cli::Validation
    attr_reader :name, :manifests, :meta

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

        unless m.has_key?("manifests") && m["manifests"].is_a?(Array)
          errors << "Manifest should contain manifests"
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
      @manifests = manifest["manifests"]
      @meta = manifest["meta"]
    end
  end
end
