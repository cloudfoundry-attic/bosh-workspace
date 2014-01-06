describe Bosh::Manifests::ManifestManager do
  describe ".discover" do
    subject { Bosh::Manifests::ManifestManager.discover work_dir }

    context "no manifests dir" do
      subject { lambda { Bosh::Manifests::ManifestManager.discover work_dir } }
      let(:work_dir) { asset_dir("empty-manifests-repo") }
      it { should raise_error Bosh::Cli::CliError }
    end

    context "manifests dir exists" do
      let(:work_dir) { asset_dir("manifests-repo") }

      it "discovers manifests" do
        expect(subject.manifests.count).to eq 1
      end

      it "validates manifests" do
        manifest = instance_double("Bosh::Manifests::Manifest")
        Bosh::Manifests::Manifest.should_receive(:new).and_return(manifest)
        manifest.should_receive(:validate)
        Bosh::Manifests::ManifestManager.discover work_dir
      end
    end
  end
end
