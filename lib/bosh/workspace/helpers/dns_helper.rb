module Bosh::Manifests
  class DnsHelper
    def self.transform(generated_manifest, domain_name)
      @manifest = YAML.load(IO.read(generated_manifest))
      
      transform_networks

      IO.write(generated_manifest, @manifest.to_yaml)
    end

    private

    def self.transform_networks
      @manifest["networks"].map! do |network| 
        if network["type"] == "manual"
          { "name" => network["name"], "type" => "dynamic", "cloud_properties" => {} }
        else
          network
        end
      end
    end
  end
end
