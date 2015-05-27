module Bosh::Workspace
  class CloudConfigHelper
    def self.transform(generated_manifest, cloud_config)
      @manifest = YAML.load(IO.read(generated_manifest))
      @networks = cloud_config['networks']

      transform_networks
      transform_manifest

      IO.write(generated_manifest, @manifest.to_yaml)
    end

    private

    def self.transform_networks
      @manifest["jobs"].map! do |job|
        job['networks'].map! do |network|
          if rename = network_map[network["name"]]
            network["name"] = rename
          end
          network
        end
        job
      end
    end

    def self.transform_networks
      @manifest["jobs"].map! do |job|
        job['networks'].map! do |network|
          if rename = network_map[network["name"]]
            network["name"] = rename
          end
          network
        end
        job
      end
    end

    def self.transform_manifest
      @manifest = @manifest.delete_if do |key|
        !%w(name director_uuid releases jobs properties update).include?(key)
      end
    end

    def self.network_map
      @networks.map { |n| [n['name'], n['rename']] }.to_h
    end
  end
end
