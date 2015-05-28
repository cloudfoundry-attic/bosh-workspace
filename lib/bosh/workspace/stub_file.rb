module Bosh::Workspace
  class StubFile
    attr_reader :name, :director_uuid

    def self.create(path, project_deployment)
      self.new(project_deployment).tap { |stub| stub.write(path) }
    end

    def initialize(project_deployment)
      @name = project_deployment.name
      @director_uuid = project_deployment.director_uuid
      @releases = project_deployment.releases
      @stemcells = project_deployment.stemcells
      @meta = project_deployment.meta
      @networks = project_deployment.networks
    end

    def write(file)
      IO.write file, content.to_yaml
    end

    def content
      content = {
        "name" => name,
        "director_uuid" => director_uuid,
        "releases" => releases,
        "meta" => meta
      }

      content["networks"] = networks if networks
      content
    end

    def releases
      @releases.map { |r| r.select { |key| %w[name version].include?(key) } }
    end

    def networks
      @networks.map do |n|
        { 'name' => n['name'], 'subnets' => [{ 'static' => n['static'] }] }
      end
    end

    def meta
      out = case @stemcells.size
      when 1
        { "stemcell" => @stemcells.first }
      else
        { "stemcells" => @stemcells }
      end
      out.merge(@meta)
    end
  end
end
