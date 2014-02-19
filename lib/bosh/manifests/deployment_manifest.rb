module Bosh::Manifests
  class DeploymentManifest
    include Bosh::Cli::Validation
    attr_writer :director_uuid

    def initialize(file)
      @file = file
      err("Deployment file does not exist: #{file}") unless File.exist? @file
      @manifest = Psych.load(File.read(@file))
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

    def director_uuid
      @director_uuid || @manifest["director_uuid"]
    end

    def merged_file
      @merged_file ||= begin
        path = File.join(file_dirname, "../.deployments", file_basename)
        FileUtils.mkpath File.dirname(path)
        File.expand_path path
      end
    end

    %w[name templates releases meta].each do |var|
      define_method var do
        @manifest[var]
      end
    end

    private

    def file_basename
      File.basename(@file)
    end

    def file_dirname
      File.dirname(@file)
    end
  end
end
