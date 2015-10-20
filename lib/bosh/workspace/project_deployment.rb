module Bosh::Workspace
  class ProjectDeployment
    include Bosh::Cli::Validation
    attr_writer :director_uuid
    attr_reader :file

    def initialize(file)
      @file = file
      err("Deployment file does not exist: #{file}") unless File.exist?(@file)
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
      return @manifest unless @manifest.nil?
      puts stub.to_json
      renderer = Bosh::Template::Renderer.new(context: stub.to_json)
      puts renderer.inspect
      @manifest = Psych.load(renderer.render(file))
    end

    def stub
      return @stub unless @stub.nil?
      stub_file = File.join(file_dirname.gsub(/\/deployments\/?$/, ''), 'stubs', file_basename)
      puts "stub_file: #{stub_file}"
      puts "stub: #{Psych.load(File.read(stub_file))}" if File.exist?(stub_file)
      @stub = File.exist?(stub_file) ? Psych.load(File.read(stub_file)) : {}
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
