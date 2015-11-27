require "bosh/workspace"

module Bosh::Cli::Command
  class ProjectDeployment < Base
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

    # Hack to unregister original deploy command
    Bosh::Cli::Config.instance_eval("@commands.delete('deploy')")

    usage "deploy"
    desc "Deploy according to the currently selected deployment manifest"
    option "--recreate", "recreate all VMs in deployment"
    option "--skip-manifest", "skip generating deployment manifest"
    def deploy
      if project_deployment? && !options[:skip_manifest]
        require_project_deployment
        build_project_deployment
      end

      command = deployment_cmd(options)
      command.perform
      @exit_code = command.exit_code
    end

    private

    def deployment_cmd(options = {})
      Bosh::Cli::Command::Deployment.new.tap do |cmd|
        options.each { |k, v| cmd.add_option k.to_sym, v }
      end
    end
  end
end
