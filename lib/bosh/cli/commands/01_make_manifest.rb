require "bosh/manifests"

module Bosh::Cli::Command
  class Manifests < Base
    include Bosh::Cli::Validation
    include Bosh::Manifests

    # Hack to unregister original deployment command
    Bosh::Cli::Config.instance_eval("@commands.delete('deployment')")

    usage "deployment"
    desc "Get/set current deployment"
    def set_current(filename = nil)
      unless filename.nil?
        manifest = DeploymentManifest.new(find_deployment(filename))

        unless manifest.valid?
          say("Validation errors:".make_red)
          manifest.errors.each do |error|
            say("- #{error}")
          end
          err("'#{filename}' is not valid".make_red)
        end
      end

      deployment_cmd(options).set_current(filename)
    end

    usage "prepare deployment"
    desc "Resolve deployment requirements"
    def prepare
      deployment_required
      auth_required

      release_manager.update_release_repos

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
      target_file = nil
      step("Generating deployment manifest",
           "Failed to generate deployment manifest") do
        target_file = ManifestBuilder.build(deployment_manifest, work_dir)
      end
      options.merge!(deployment: target_file)
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

    def deployment_manifest
      @deployment_manifest ||= DeploymentManifest.new(deployment)
    end

    def release_manager
      @release_manager ||= begin
        ReleaseManager.new(deployment_manifest.releases, work_dir)
      end
    end
  end
end
