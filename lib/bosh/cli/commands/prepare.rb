require "bosh/workspace"

module Bosh::Cli::Command
  class Prepare < Base
    include Bosh::Cli::Validation
    include Bosh::Workspace
    include ProjectDeploymentHelper

    usage "prepare deployment"
    desc "Resolve deployment requirements"
    def prepare
      require_project_deployment
      auth_required

      project_deployment_releases.each do |release|
        say "Resolving release version for '#{release.name}'"
        release.update_repo

        remote_release = director.get_release(release.name) rescue nil
        if remote_release && remote_release["versions"].include?(release.version.to_s)
          say "Release '#{release.name_version}' already exists. Skipping upload."
        else
          say "Uploading '#{release.name_version}'"
          release_cmd.upload(release.manifest_file)
        end
      end

#      project_deployment_stemcells.each do |stemcell|
#        stemcell_cmd().upload unless stemcell.exists?
#      end
    end

    private

    def release_cmd(options = {})
      Bosh::Cli::Command::Release.new.tap do |cmd|
        options.each { |k, v| cmd.add_option k.to_sym, v }
      end
    end
  end
end
