module Bosh::Workspace
  class ProjectDeployment
    include Bosh::Cli::Validation
    include Bosh::Exec
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
      @manifest = YAML.load(ERB.new(IO.read(file)).result)
      validate_stub! unless stub.empty?
      @manifest = recursive_merge(@manifest, stub) unless stub.empty?
      @manifest
    end

    def stub
      return @stub unless @stub.nil?
      @stub = stub_file ? load_stub : {}
    end

    %w[name templates releases stemcells meta domain_name].each do |var|
      define_method var do
        manifest[var]
      end
    end

    private

    def stubs_dir
      File.expand_path(File.join(file_dirname, "../stubs"))
    end

    def stub_file
      Dir[File.join(stubs_dir, "#{file_basename('.*')}*")].first
    end

    def executable_stub?
      File.executable?(stub_file)
    end

    def load_stub
      begin
        YAML.load(executable_stub? ? execute_stub! : IO.read(stub_file))
      rescue Psych::SyntaxError => e
        say "Error loading stub file for deployment #{file} due to invalid YAML"
        err "error: #{e.message}"
      end
    end

    def execute_stub!
      sh(stub_file, yield: :on_false) do |result|
        execute_stub_failed!(result.command, result.output) if result.failed?
      end.output
    end

    def execute_stub_failed!(stub, output)
      say("An error occured while executing stub file: #{stub}")
      err("error: '#{output}'")
    end

    def validate_stub!
      return unless stub.keys.any? { |k| !STUB_WHITELIST.include?(k) }
      offending_keys = stub.keys - STUB_WHITELIST
      err "Key: '#{offending_keys.first}' not allowed in stub file"
    end

    def file_basename(filter = '')
      File.basename(@file, filter)
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
