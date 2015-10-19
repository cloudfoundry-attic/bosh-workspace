module Bosh::Workspace
  class ProjectDeployment
    include Bosh::Cli::Validation
    attr_writer :director_uuid
    attr_reader :file

    def initialize(file)
      @file = file
      err("Deployment file does not exist: #{file}") unless File.exist? @file
    end

    def perform_validation(options = {})
      Schemas::ProjectDeployment.new.validate manifest
    rescue Membrane::SchemaValidationError => e
      errors << e.message
    end

    def director_uuid
      @director_uuid || manifest["director_uuid"]
    end

    def merged_file
      @merged_file ||= begin
        path = File.join(file_dirname, "../.deployments", file_basename)
        FileUtils.mkpath File.dirname(path)
        File.expand_path path
      end
    end

    def manifest
      @manifest ||= Psych.load(ERB.new(File.read(file)).result)
    end

    %w[name templates releases stemcells meta domain_name].each do |var|
      define_method var do
        manifest[var]
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
