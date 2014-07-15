require "bosh/workspace"

module Bosh::Cli::Command
  class Workspace < Base
    include Bosh::Cli::Validation
    include Bosh::Workspace
    include ProjectDeploymentHelper

    # Hack to unregister original deployment command
    Bosh::Cli::Config.instance_eval("@commands.delete('deployment')")

    usage "deployment"
    desc "Get/set current deployment"
    def set_current(filename = nil)
      unless filename.nil?
        deployment = find_deployment(filename)

        if project_deployment_file?(deployment)
          self.project_deployment = deployment
          validate_project_deployment
          filename = project_deployment.merged_file
          create_placeholder_deployment unless File.exists?(filename)
        end
      end

      deployment_cmd(options).set_current(filename)
    end

    usage "prepare deployment"
    desc "Resolve deployment requirements"
    def prepare
      require_project_deployment
      auth_required

      nl
      say "Preparing releases:"
      project_deployment_releases.each do |release|
        release.checkout_current_version
        say "- #{release.name}/#{release.version}"
      end
      nl

      # TODO: Implement
      # current_deployment.stemcells.each do |stemcell|
      #   stemcell.upload unless stemcell.exists?
      # end
    end

    # Hack to unregister original deploy command
    Bosh::Cli::Config.instance_eval("@commands.delete('deploy')")

    usage "deploy"
    desc "Deploy according to the currently selected deployment manifest"
    option "--recreate", "recreate all VMs in deployment"
    def deploy
      if project_deployment?
        require_project_deployment
        build_project_deployment
      end

      deployment_cmd(options).perform
    end

    private

    def deployment_cmd(options = {})
      cmd ||= Bosh::Cli::Command::Deployment.new
      options.each do |key, value|
        cmd.add_option key.to_sym, value
      end
      cmd
    end
  end
end
