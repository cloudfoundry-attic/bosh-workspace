require "bosh/cli/commands/project_deployment"

describe Bosh::Cli::Command::ProjectDeployment do
  let(:command) { Bosh::Cli::Command::ProjectDeployment.new }
  let(:project_deployment) do
    instance_double("Bosh::Workspace::DeploymentManifest")
  end

  let(:deployment_cmd) { instance_double("Bosh::Cli::Command::Deployment") }

  before do
    setup_home_dir
    command.add_option(:config, home_file(".bosh_config"))
    command.add_option(:non_interactive, true)
    allow(deployment_cmd).to receive(:add_option)
  end

  describe "#deployment" do
    subject { command.set_current(filename) }

    let(:filename) { "foo" }

    before do
      expect(Bosh::Cli::Command::Deployment).to receive(:new)
        .and_return(deployment_cmd)
    end

    context "with project deployment" do
      let(:deployment) { "deployments/foo.yml" }
      let(:merged_file) { ".manifests/foo.yml" }

      it "sets filename to merged file" do
        expect(command).to receive(:find_deployment).with(filename)
          .and_return(deployment)
        expect(command).to receive(:project_deployment_file?).with(deployment)
          .and_return(true)
        expect(command).to receive(:project_deployment=).with(deployment)
        expect(command).to receive(:validate_project_deployment)
        expect(File).to receive(:exists?).with(merged_file).and_return(false)
        expect(command).to receive(:create_placeholder_deployment)
        expect(command).to receive(:project_deployment)
          .and_return(project_deployment)
        expect(project_deployment).to receive(:merged_file)
          .and_return(merged_file)
        expect(deployment_cmd).to receive(:set_current).with(merged_file)
        subject
      end
    end

    context "without filename" do
      let(:filename) { nil }

      it "returns current deployment" do
        expect(deployment_cmd).to receive(:set_current).with(filename)
        subject
      end
    end
  end

  describe "deploy" do
    subject { command.deploy }

    before do
      expect(Bosh::Cli::Command::Deployment).to receive(:new)
        .and_return(deployment_cmd)
      expect(command).to receive(:project_deployment?)
        .and_return(is_project_deployment)
      expect(deployment_cmd).to receive(:perform)
      expect(deployment_cmd).to receive(:exit_code).and_return(exit_code)
    end

    context "with project deployment" do
      let(:is_project_deployment) { true }
      let(:exit_code) { 0 }

      it "requires project deployment" do
        expect(command).to receive(:require_project_deployment)
        expect(command).to receive(:build_project_deployment)
        subject
      end
    end

    context "with normal deployment" do
      let(:is_project_deployment) { false }
      let(:exit_code) { 0 }

      it "deploys" do
        subject
        expect(command.exit_code).to eq(0)
      end
    end

    context "with failing deployment" do
      let(:is_project_deployment) { false }
      let(:exit_code) { 1 }

      it "reports the exit_code correctly" do
        subject
        expect(command.exit_code).to eq(1)
      end
    end
  end
end
