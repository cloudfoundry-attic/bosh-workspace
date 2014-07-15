require "bosh/cli/commands/workspace"

describe Bosh::Cli::Command::Workspace do
  let(:command) { Bosh::Cli::Command::Workspace.new }
  let(:project_deployment) do
    instance_double("Bosh::Workspace::DeploymentManifest")
  end

  let(:deployment_cmd) { instance_double("Bosh::Cli::Command::Deployment") }

  before do
    setup_home_dir
    command.add_option(:config, home_file(".bosh_config"))
    command.add_option(:non_interactive, true)
    deployment_cmd.stub(:add_option)
  end

  describe "#deployment" do
    subject { command.set_current(filename) }

    let(:filename) { "foo" }

    before do
      Bosh::Cli::Command::Deployment.should_receive(:new)
        .and_return(deployment_cmd)
    end

    context "with project deployment" do
      let(:deployment) { "deployments/foo.yml" }
      let(:merged_file) { ".manifests/foo.yml" }

      it "sets filename to merged file" do
        command.should_receive(:find_deployment).with(filename)
          .and_return(deployment)
        command.should_receive(:project_deployment_file?).with(deployment)
          .and_return(true)
        command.should_receive(:project_deployment=).with(deployment)
        command.should_receive(:validate_project_deployment)
        File.should_receive(:exists?).with(merged_file).and_return(false)
        command.should_receive(:create_placeholder_deployment)
        command.should_receive(:project_deployment)
          .and_return(project_deployment)
        project_deployment.should_receive(:merged_file).and_return(merged_file)
        deployment_cmd.should_receive(:set_current).with(merged_file)
        subject
      end
    end

    context "without filename" do
      let(:filename) { nil }

      it "returns current deployment" do
        deployment_cmd.should_receive(:set_current).with(filename)
        subject
      end
    end
  end

  describe "#prepare" do
    subject { command.prepare }
    let(:releases) { ["foo", "bar"] }
    let(:release_manager) { instance_double("Bosh::Workspace::ReleaseManager") }
    let(:work_dir) { asset_dir("manifests-repo") }

    it "resolves deployment requirements" do
      command.should_receive(:require_project_deployment)
      command.should_receive(:auth_required)
      command.should_receive(:project_deployment).and_return(project_deployment)
      project_deployment.should_receive(:releases).and_return(releases)
      command.should_receive(:work_dir).and_return(work_dir)
      Bosh::Workspace::ReleaseManager.should_receive(:new)
        .with(releases, work_dir).and_return(release_manager)
      release_manager.should_receive(:update_release_repos)
      subject
    end
  end

  describe "deploy" do
    subject { command.deploy }

    before do
      Bosh::Cli::Command::Deployment.should_receive(:new)
        .and_return(deployment_cmd)
      command.should_receive(:project_deployment?)
        .and_return(is_project_deployment)
      deployment_cmd.should_receive(:perform)
    end

    context "with project deployment" do
      let(:is_project_deployment) { true }

      it "requires project deployment" do
        command.should_receive(:require_project_deployment)
        command.should_receive(:build_project_deployment)
        subject
      end
    end

    context "with normal deployment" do
      let(:is_project_deployment) { false }

      it "deploys" do
        subject
      end
    end
  end
end
