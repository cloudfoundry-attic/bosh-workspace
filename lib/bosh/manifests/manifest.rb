module Bosh::Manifests
  class Manifest
    include Bosh::Cli::Validation
    def initialize(manifest_file)
      @manifest_file = manifest_file
    end

    def perform_validation(options = {})
      manifest_yaml = File.read(@manifest_file)
      manifest = Psych.load(manifest_yaml)

      step("Manifest file", "Manifest should be a hash", :fatal) do
        manifest.is_a?(Hash)
      end

      step("Manifest properties", "Manifest should contain a valid name") do
        manifest.has_key?("name") && manifest["name"].is_a?(String)
      end

      step("Manifest properties", "Manifest should contain manifests") do
        manifest.has_key?("manifests") && manifest["manifests"].is_a?(Array)
      end

      step("Manifest properties", "Manifest should contain meta hash") do
        manifest.has_key?("meta") && manifest["meta"].is_a?(Hash)
      end

      @manifest = manifest
    end
  end
end
