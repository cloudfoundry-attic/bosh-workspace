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
      current_workspace_patch.to_file(workspace_patch)
      say "Wrote patch to #{workspace_patch}"
    end

    usage "workspace apply patch"
    desc "Apply patch information from all deployments in current workspace"
    def apply(workspace_patch)
      patch = WorkspacePatch.from_file(workspace_patch)
      validate_workspace_patch(patch, workspace_patch)
      patch.apply(deployment_files, templates_dir)
      say "Successfully applied workspace patch:"
      print_changes(current_workspace_patch.changes(patch))
    end

    private

    def current_workspace_patch
      @current_patch ||= WorkspacePatch.create(
        project_deployment_files,
        templates_dir
      )
    end

    def templates_dir
      File.join(work_dir, "templates")
    end

    def print_changes(changes)
      changes.each do |key, value|
        title = key.to_s.gsub(/[-_]/, ' ').capitalize
        header title.make_green
        case value
        when String
          say(value)
        when Hash
          value.each do |sub_key, sub_value|
            say "file: deployments/#{sub_key}.yml".make_green
            say sub_value
          end
        end
      end
    end

    def validate_workspace_patch(patch, file)
      unless patch.valid?
        say("Validation errors:".make_red)
        patch.errors.each { |error| say("- #{error}") }
        err("'#{file}' is not valid".make_red)
      end
    end

    def project_deployment_files
      deployments.each_with_object({}) do |d, h|
        h[d.base_name] = File.join(work_dir, d.project_deployment_file)
      end
    end
  end
end
