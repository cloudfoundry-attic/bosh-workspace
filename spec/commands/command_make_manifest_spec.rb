require "bosh/cli/commands/01_make_manifest"

describe Bosh::Cli::Command::Manifests do

  let(:command) { Bosh::Cli::Command::Manifests.new }
  let(:director) { instance_double("Bosh::Cli::Director") }
  let(:work_dir) { asset_dir("manifests-repo") }

  before do
    setup_home_dir
    command.add_option(:config, home_file(".bosh_config"))
    command.add_option(:non_interactive, true)
    command.stub(:work_dir).and_return(work_dir)
  end

  context "list manifests" do
    it "prints" do
      manifest_manager = instance_double("Bosh::Manifests::ManifestManager")
      Bosh::Manifests::ManifestManager.should_receive(:discover).with(work_dir).
        and_return(manifest_manager)
      manifest_manager.should_receive(:print_manifests)
      command.manifests
    end
  end


  it "creates bosh manifest" do
    command.make_manifest
  end

end
