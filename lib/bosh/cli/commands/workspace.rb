require "bosh/workspace"

module Bosh::Cli::Command
  class Workspace < Base
    include Bosh::Workspace
    include WorkspaceDeploymentsHelper

    usage "workspace deploy"
    desc "Deploy according to the current workspace directory"
    def deploy_workspace
      with_deployment_context do
        bosh_prepare_deployment
        bosh_deploy
      end

      with_deployment_context do |deployment|
        deployment.errands.each do |errand|
          bosh_run_errand(errand)
        end
      end
    end

    usage "workspace create patch"
    desc "Extract patch information from all deployments in current workspace"
    def create(workspace_patch)
      patch = WorkspacePatch.create(
        project_deployment_files, File.join(work_dir, "templates")
      )
      patch.to_file(workspace_patch)
      say "Wrote patch to #{workspace_patch}"
    end

    usage "workspace apply patch"
    desc "Apply patch information from all deployments in current workspace"
    def apply(workspace_patch)

    end

    def project_deployment_files
      deployments.each_with_object({}) do |d, h|
        h[d.base_name] = File.join(work_dir, d.project_deployment_file)
      end
    end
  end
end
