require "membrane"
module Bosh::Workspace
  class DeploymentManifest
    include Bosh::Cli::Validation
    attr_writer :director_uuid
    attr_reader :file

    RELEASE_SCHEMA = Membrane::SchemaParser.parse do
      {
        "name"    => String,
        "version" => enum(Integer, "latest"),
        "git"     => String,
      }
    end

    UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

    PROJECT_DEPLOYMENT_SCHEMA = Membrane::SchemaParser.parse do
      {
        "name"                  => String,
        "director_uuid"         => enum(UUID_REGEX, "current"),
        optional("domain_name") => String,
        "releases"              => [RELEASE_SCHEMA],
        "templates"             => [String],
        "meta"                  => Hash
      }
    end

    def initialize(file)
      @file = file
      err("Deployment file does not exist: #{file}") unless File.exist? @file
      @manifest = Psych.load(File.read(@file))
    end

    def perform_validation(options = {})
      PROJECT_DEPLOYMENT_SCHEMA.validate @manifest
    rescue Membrane::SchemaValidationError => e
      errors << e.message
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

    %w[name templates releases meta domain_name].each do |var|
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
