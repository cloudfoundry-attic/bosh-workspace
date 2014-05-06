module Bosh::Manifests
  class DnsHelper
    def self.transform(generated_manifest, domain_name)
      @manifest = YAML.load(IO.read(generated_manifest))
      @manual_networks = []      

      transform_networks
      transform_jobs

      IO.write(generated_manifest, @manifest.to_yaml)
    end

    private

    def self.transform_networks
      @manifest["networks"].map! do |network| 
        if network["type"] == "manual"
          @manual_networks << network["name"]
          { "name" => network["name"], "type" => "dynamic", "cloud_properties" => {} }
        else
          network
        end
      end
    end
    
    def self.transform_jobs
      @manifest["jobs"].map! do |job|
        job["networks"].map! do |network|
          if @manual_networks.include? network["name"]
            network.delete("static_ips")
          end
          network
        end
        job
      end
    end
  end
end
