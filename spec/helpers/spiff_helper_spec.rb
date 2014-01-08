describe Bosh::Manifests::SpiffHelper do
  describe ".spiff" do
    class SpiffHelperTester
      include Bosh::Manifests::SpiffHelper
    end
    subject { SpiffHelperTester.new }
    let(:path) { asset_dir("bin") }
    let(:templates) { ["foo.yml", "bar.yml"] }
    let(:target_file) { "spiffed_manifest.yml" }

    before do
      ENV["PATH"] = path
    end

    context "spiff not in path" do
      let(:path) { asset_dir("empty_bin") }
      it "raises an error" do
        expect{ subject.spiff_merge templates, target_file }
          .to raise_error /make sure spiff is installed/
      end
    end

    describe ".merge" do
      let(:file) { instance_double("File") }
      let(:output) { "---\n{}" }
      let(:result) { Bosh::Exec::Result.new("spiff", output, 0, false) }

      it "merges manifests" do
        subject.should_receive(:sh).and_yield(result)
        File.should_receive(:open).with(target_file, 'w').and_yield(file)
        file.should_receive(:write).with(output)
        subject.spiff_merge templates, target_file
      end
    end
  end
end
