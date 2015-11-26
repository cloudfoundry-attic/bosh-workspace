module Bosh::Workspace
  module StemcellHelper
    include ProjectDeploymentHelper

    def stemcell_upload_url(stemcell_url)
      say "Uploading stemcell from URL '#{stemcell_url}'"
      nl
      stemcell_cmd.upload(stemcell_url)
    end

    def stemcell_uploaded?(name, version)
      existing = director.list_stemcells.select do |sc|
        sc['name'] == name && sc['version'] == version.to_s
      end

      !existing.empty? 
    end

    def project_deployment_stemcells
      @stemcells ||= begin
        project_deployment.stemcells.map { |s| Stemcell.new(s) }
      end
    end

    private

    def stemcell_cmd
      @stemcell_cmd ||= Bosh::Cli::Command::Stemcell.new
    end
  end
end
