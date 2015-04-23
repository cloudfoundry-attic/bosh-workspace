module Bosh::Workspace
  class Deployment
    def initialize(deployment)
      schema.validate deployment
      @raw = OpenStruct.new(deployment)
    end

    def name
      file = File.join 'deployments', file_name
      YAML.load_file(file)["name"]
    end

    def target
      return @raw.target unless @raw.target =~ /@/
      @raw.target.split('@')[1]
    end

    def username
      return "admin" unless @raw.target =~ /@/
      @raw.target.match(/^([^@:]+)/)[1] || "admin"
    end

    def password
      return "admin" unless @raw.target =~ /@/
      match = @raw.target.match(/^[^:@]+:([^@]+)/)
      match && match[1] || "admin"
    end

    def merged_file
      File.join ".deployments", file_name
    end

    def base_name
      @raw.name
    end

    def file_name
      @raw.name + ".yml"
    end

    def errands
      @raw.errands
    end

    def project_deployment_file
      File.join "deployments", file_name
    end

    private

    def schema
      Membrane::SchemaParser.parse do
        {
          "name"                   => /^((?!\.yml).)*$/, # Should not contain .yml
          "target"                 => String,
          optional("errands")      => [String]
        }
      end
    end
  end
end
