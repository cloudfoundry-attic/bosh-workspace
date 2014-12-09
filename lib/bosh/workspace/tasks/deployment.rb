module Bosh::Workspace::Tasks
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
      @raw.target.split('@')[1]
    end

    def username
      @raw.target.match(/^([^@:]+)/)[1] || "admin"
    end

    def password
      match = @raw.target.match(/^[^:@]+:([^@]+)/)
      match && match[1] || "admin"
    end

    def merged_file
      File.join ".deployments", file_name
    end

    def file_name
      @raw.name + ".yml"
    end

    def errands
      @raw.errands
    end

    def apply_patch
      @raw.apply_patch
    end

    def create_patch
      @raw.create_patch
    end

    private

    def schema
      Membrane::SchemaParser.parse do
        {
          "name"                   => /^((?!\.yml).)*$/, # Should not contain .yml
          "target"                 => String,
          optional("apply_patch")  => String,
          optional("create_patch") => String,
          optional("errands")      => [String]
        }
      end
    end
  end
end
