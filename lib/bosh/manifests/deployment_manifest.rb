module Bosh::Manifests
  class DeploymentManifest
    include Bosh::Cli::Validation
    attr_reader :name, :director_uuid, :templates, :releases, :meta

    def initialize(file)
      err("Deployment file does not exist: #{file}") unless File.exist? file
      @manifest = Psych.load(File.read(file))
    end

    def perform_validation(options = {})
      if @manifest.is_a?(Hash)
        unless @manifest.has_key?("name") && @manifest["name"].is_a?(String)
          errors << "Manifest should contain a name"
        end

        unless @manifest.has_key?("director_uuid") && @manifest["director_uuid"].is_a?(String)
          errors << "Manifest should contain a director_uuid"
        end

        unless @manifest.has_key?("templates") && @manifest["templates"].is_a?(Array)
          errors << "Manifest should contain templates"
        end

        unless @manifest.has_key?("releases") && @manifest["releases"].is_a?(Array)
          errors << "Manifest should contain releases"
        end

        unless @manifest.has_key?("meta") && @manifest["meta"].is_a?(Hash)
          errors << "Manifest should contain meta hash"
        end
      else
        errors << "Manifest should be a hash"
      end
    end

    %w[name director_uuid templates releases meta].each do |var|
      define_method var do
        @manifest[var]
      end
    end
  end
end
