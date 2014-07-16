require "bosh/cli/commands/prepare"

describe Bosh::Cli::Command::Prepare do
  describe "#prepare" do
    let(:command) { Bosh::Cli::Command::Prepare.new }
    let(:manifest_file) { "releases/foo-1.yml" }
    let(:release_cmd) { instance_double("Bosh::Cli::Command::Release") }
    let(:release) do 
      instance_double("Bosh::Workspace::Release",
        name: "foo", version: "1", repo_dir: ".releases/foo",
        manifest_file: manifest_file)
    end

    before do
      Bosh::Cli::Command::Release.stub(:new).and_return(release_cmd)
      command.stub(:require_project_deployment)
      command.stub(:auth_required)
      command.stub(:project_deployment_releases).and_return([release])
    end

    it "resolves deployment requirements" do
      release.should_receive(:update_repo)
      release_cmd.should_receive(:add_option).with(:skip_if_exists, true)
      release_cmd.should_receive(:upload).with(manifest_file)
      command.prepare
    end
  end
end
