require "bosh/cli/commands/01_make_manifest"

describe Bosh::Cli::Command::Manifests do
  let(:command) { Bosh::Cli::Command::Manifests.new }
  let(:work_dir) { asset_dir("manifests-repo") }
  let(:manifest) { instance_double("Bosh::Manifests::DeploymentManifest") }
  let(:filename) { "foo" }
  let(:filename_path) { File.join(work_dir, "deployments", "#{filename}.yml") }
  let(:deployment_cmd) { instance_double("Bosh::Cli::Command::Deployment") }

  before do
    setup_home_dir
    command.add_option(:config, home_file(".bosh_config"))
    command.add_option(:non_interactive, true)
    command.stub(:work_dir).and_return(work_dir)
  end

  describe "#deployment" do
    subject { command.set_current(filename) }

    context "filename given" do
      let(:valid) { true }

      before do
        Bosh::Manifests::DeploymentManifest.should_receive(:new)
          .with(filename_path).and_return(manifest)
        manifest.should_receive(:valid?).and_return(valid)
      end

      it "sets current deployment" do
        Bosh::Cli::Command::Deployment.should_receive(:new)
          .and_return(deployment_cmd)
        deployment_cmd.should_receive(:add_option).twice
        deployment_cmd.should_receive(:set_current).with(filename)
        subject
      end

      context "validation errors" do
        let(:valid) { false }

        it "raises validation errors" do
          manifest.should_receive(:errors).and_return(%w[foo-error])
          command.should_receive(:say).with("Validation errors:")
          command.should_receive(:say).with("- foo-error")
          expect { subject }.to raise_error /is not valid/
        end
      end
    end

    context "no filename given" do
      let(:filename) { nil }

      it "returns current deployment" do
        Bosh::Cli::Command::Deployment.should_receive(:new)
          .and_return(deployment_cmd)
        deployment_cmd.should_receive(:add_option).twice
        deployment_cmd.should_receive(:set_current).with(filename)
        subject
      end
    end
  end

  describe "#prepare" do
    subject { command.prepare }
    let(:releases) { ["foo", "bar"] }
    let(:release_manager) { instance_double("Bosh::Manifests::ReleaseManager") }

    before do
      command.should_receive(:deployment_required)
      command.should_receive(:auth_required)
      command.should_receive(:deployment).and_return(filename_path)
      Bosh::Manifests::DeploymentManifest.should_receive(:new)
        .with(filename_path).and_return(manifest)
      manifest.should_receive(:releases).and_return(releases)
      Bosh::Manifests::ReleaseManager.should_receive(:new)
        .with(releases).and_return(release_manager)
      release_manager.should_receive(:update_release_repos)
    end

    it "resolves deployment requirements" do
      subject
    end
  end

  describe "deploy" do
    subject { command.deploy }
    let(:deployment_manifest) {
      instance_double("Bosh::Manifests::DeploymentManifest")
    }
    let(:target_file) { File.join(work_dir, ".manifests/foo.yml") }

    before do
      Bosh::Manifests::DeploymentManifest.should_receive(:new)
        .and_return(deployment_manifest)
      Bosh::Manifests::ManifestBuilder.should_receive(:build)
        .with(deployment_manifest, work_dir).and_return(target_file)
      Bosh::Cli::Command::Deployment.should_receive(:new)
        .and_return(deployment_cmd)
    end

    it "deploy" do
      deployment_cmd.should_receive(:add_option).twice
      deployment_cmd.should_receive(:add_option).with(:recreate, true)
      deployment_cmd.should_receive(:add_option).with(:deployment, target_file)
      deployment_cmd.should_receive(:perform)
      command.add_option(:recreate, true)
      subject
    end
  end
end
