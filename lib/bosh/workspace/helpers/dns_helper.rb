module Bosh::Manifests
  class DnsHelper
    def self.transform(generated_manifest, domain_name)
      @manifest = YAML.load(IO.read(generated_manifest))
      @domain_name = domain_name
      @manual_networks = []
      @dns = {}

      transform_networks
      transform_jobs
      transform_properties
      transform_job_properties

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
          if @manual_networks.include?(network["name"]) && network["static_ips"]
            network["static_ips"].each_with_index do |ip, index|
              @dns[ip] = job_to_dns(job, index, network["name"])
            end
            network.delete("static_ips")
          end
          network
        end
        job
      end
    end
    
    def self.transform_properties
      @manifest["properties"] = replace_ips(@manifest["properties"])
    end

    def self.transform_job_properties
      @manifest["jobs"].map! do |job|
        job["properties"] = replace_ips(job["properties"]) if job["properties"]
        job
      end
    end

    def self.job_to_dns(job, index, network_name)
      [index, job["name"], network_name, @manifest["name"], @domain_name].join(".")
    end

    def self.replace_ips(properties)
      properties_yaml = properties.to_yaml
      @dns.each { |ip, domain| properties_yaml.gsub!(ip, domain) }
      YAML.load properties_yaml
    end
  end
end
