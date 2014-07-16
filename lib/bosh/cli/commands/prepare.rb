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
        say "Cloning release: #{release.name} into #{release.repo_dir}"
        release.update_repo
        say "Uploading: #{release.name}/#{release.version}"
        release_cmd(skip_if_exists: true).upload(release.manifest_file)
      end

      # TODO: Implement
      # current_deployment.stemcells.each do |stemcell|
      #   stemcell.upload unless stemcell.exists?
      # end
    end

    private

    def release_cmd(options = {})
      Bosh::Cli::Command::Release.new.tap do |cmd|
        options.each { |k, v| cmd.add_option k.to_sym, v }
      end
    end
  end
end
