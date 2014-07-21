require "bosh/workspace"

module Bosh::Cli::Command
  class Prepare < Base
    include Bosh::Cli::Validation
    include Bosh::Workspace
    include ProjectDeploymentHelper
    include StemcellHelper

    usage "prepare deployment"
    desc "Resolve deployment requirements"
    def prepare
      require_project_deployment
      auth_required
      nl
      prepare_release_repos
      nl
      prepare_releases
      nl
      prepare_stemcells
    end

    private

    def release_cmd(options = {})
      Bosh::Cli::Command::Release.new.tap do |cmd|
        options.each { |k, v| cmd.add_option k.to_sym, v }
      end
    end

    def prepare_release_repos
      project_deployment_releases.each do |release|
        say "Cloning release '#{release.name.make_green}' to satisfy template references"
        release.update_repo
        say "Version '#{release.version.to_s.make_green}' has been checkout into: #{release.repo_dir}"
      end
    end

    def prepare_releases
      project_deployment_releases.each do |release|
        remote_release = director.get_release(release.name) rescue nil
        if remote_release && remote_release["versions"].include?(release.version.to_s)
          say "Release '#{release.name_version.make_green}' exists"
          say "Skipping upload"
        else
          say "Uploading '#{release.name_version.make_green}'"
          release_cmd.upload(release.manifest_file)
        end
      end
    end

    def prepare_stemcells
      project_deployment_stemcells.each do |stemcell|
        prepare_stemcell(stemcell)
      end
    end

    def prepare_stemcell(stemcell)
      if stemcell_uploaded?(stemcell.name, stemcell.version)
        say "Stemcell '#{stemcell.name_version.make_green}' exists"
        say "Skipping upload"
      else
        cached_stemcell_upload(stemcell)
      end
    end
    
    def cached_stemcell_upload(stemcell) 
      unless stemcell.downloaded?
        say "Downloading '#{stemcell.name_version.make_green}'"
        stemcell_download(stemcell.file_name) 
      end
      say "Uploading '#{stemcell.name_version.make_green}'"
      stemcell_upload(stemcell.file)
    end
  end
end
