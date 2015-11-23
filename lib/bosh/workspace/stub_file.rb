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
    end

    def write(file)
      IO.write file, content.to_yaml
    end

    def content
      {
        "name" => name,
        "director_uuid" => director_uuid,
        "releases" => releases,
        "meta" => meta
      }
    end

    def releases
      filter_keys(@releases, %w(name version))
    end

    def meta
      stemcells_meta.merge(@meta)
    end

    private

    def filter_keys(array, keys)
      array.map { |s| s.select { |key| keys.include?(key) } }
    end

    def stemcells
      filter_keys(@stemcells, %w(name version))
    end

    def stemcell
      stemcells[1] ? nil : stemcells[0]
    end

    def stemcells_meta
      stemcell.nil? ? { 'stemcells' => stemcells } : { 'stemcell' => stemcell }
    end
  end
end
