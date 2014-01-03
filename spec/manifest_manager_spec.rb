describe Bosh::Manifests::ManifestManager do
  describe ".discover" do
    subject(:manager) { Bosh::Manifests::ManifestManager.discover work_dir }

    context "no manifests dir" do
      subject { lambda { Bosh::Manifests::ManifestManager.discover work_dir } }
      let(:work_dir) { asset_dir("empty-manifests-repo") }
      it { should raise_error Bosh::Cli::CliError }
    end

    context "manifests dir exists" do
      let(:work_dir) { asset_dir("manifests-repo") }
      it "discovers manifests" do
        expect(manager.manifests.count).to eq 1
      end
    end
  end

end
