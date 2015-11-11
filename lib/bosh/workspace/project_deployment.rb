module Bosh::Workspace
  class ProjectDeployment
    include Bosh::Cli::Validation
    attr_writer :director_uuid, :stub
    attr_reader :file

    STUB_WHITELIST = %w(name director_uuid meta)

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

    def merge_tool
      Bosh::Workspace::MergeTool.new(manifest['merge_tool'])
    end

    def manifest
      return @manifest unless @manifest.nil?
      @manifest = Psych.load(ERB.new(File.read(file)).result)
      validate_stub! unless stub.empty?
      @manifest = recursive_merge(@manifest, stub) unless stub.empty?
      @manifest
    end

    def stub
      return @stub unless @stub.nil?
      stub_file = File.expand_path(File.join(file_dirname, "../stubs", file_basename))
      @stub = File.exist?(stub_file) ? Psych.load(File.read(stub_file)) : {}
    end

    %w[name templates releases stemcells meta domain_name].each do |var|
      define_method var do
        manifest[var]
      end
    end

    private

    def validate_stub!
      return unless stub.keys.any? { |k| !STUB_WHITELIST.include?(k) }
      offending_keys = stub.keys - STUB_WHITELIST
      err "Key: '#{offending_keys.first}' not allowed in stub file"
    end

    def file_basename
      File.basename(@file)
    end

    def file_dirname
      File.dirname(@file)
    end

    def recursive_merge(source, target)
      source.merge(target) do |_, old_value, new_value|
        if old_value.class == Hash && new_value.class == Hash
          recursive_merge(old_value, new_value)
        else
          new_value
        end
      end
    end
  end
end
