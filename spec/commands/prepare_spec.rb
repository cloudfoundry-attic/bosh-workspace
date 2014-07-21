require "bosh/cli/commands/prepare"

describe Bosh::Cli::Command::Prepare do
  describe "#prepare" do
    let(:command) { Bosh::Cli::Command::Prepare.new }
    let(:manifest_file) { "releases/foo-1.yml" }
    let(:release_cmd) { instance_double("Bosh::Cli::Command::Release") }
    let(:remote_releases) { { "versions" => remote_versions } }
    let(:remote_versions) { [ "1" ] }
    let(:release) do 
      instance_double("Bosh::Workspace::Release",
        name: "foo", version: "1", repo_dir: ".releases/foo",
        name_version: "foo/1", manifest_file: manifest_file)
    end

    before do
      Bosh::Cli::Command::Release.stub(:new).and_return(release_cmd)
      command.stub(:require_project_deployment)
      command.stub(:auth_required)
      command.stub(:project_deployment_releases).and_return([release])
      command.stub(:project_deployment_stemcells).and_return([])
      command.stub_chain("director.get_release").and_return(remote_releases)
    end

    context "release does not exist" do
      it "resolves deployment requirements" do
        command.stub_chain("director.get_release").and_raise("Release 'foo' doesn't exist`")
        release.should_receive(:update_repo)
        release_cmd.should_receive(:upload).with(manifest_file)
        command.prepare
      end
    end

    context "release version does not exist" do
      let(:remote_versions) { [] }
      it "resolves deployment requirements" do
        release.should_receive(:update_repo)
        release_cmd.should_receive(:upload).with(manifest_file)
        command.prepare
      end
    end

    context "release  exist" do
      it "resolves deployment requirements" do
        release.should_receive(:update_repo)
        release_cmd.should_not_receive(:upload)
        command.prepare
      end
    end
  end
end
