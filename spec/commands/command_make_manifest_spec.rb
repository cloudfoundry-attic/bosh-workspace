require "bosh/cli/commands/01_make_manifest"

describe Bosh::Cli::Command::Manifests do

  let(:command) { Bosh::Cli::Command::Manifests.new }
  let(:work_dir) { asset_dir("manifests-repo") }
  let(:manifest_manager) { instance_double("Bosh::Manifests::ManifestManager") }

  before do
    setup_home_dir
    command.add_option(:config, home_file(".bosh_config"))
    command.add_option(:non_interactive, true)
    command.stub(:work_dir).and_return(work_dir)
    Bosh::Manifests::ManifestManager.should_receive(:discover).with(work_dir).
      and_return(manifest_manager)
    manifest_manager.should_receive(:validate_manifests)
  end

  describe "#manifests" do
    let(:table) { "| Name | File |"}

    it "outputs manifest table" do
      manifest_manager.should_receive(:to_table).and_return(table)
      command.should_receive(:nl)
      command.should_receive(:say).with(table)
      command.should_receive(:nl)
      command.manifests
    end
  end

  describe "#build_manifest" do
    let(:name) { "foo" }
    let(:manifest) { instance_double("Bosh::Manifests::Manifest") }
    let(:manifest_builder) { Bosh::Manifests::ManifestBuilder }

    it "generates a manifest" do
      manifest_manager.should_receive(:find).with(name).and_return(manifest)
      manifest_builder.should_receive(:build).with(manifest, work_dir)
        .and_return("target_manifest")
      command.should_receive(:say).with(/build succesfull: 'target_manifest'/)
      command.build_manifest name
    end
  end
end
