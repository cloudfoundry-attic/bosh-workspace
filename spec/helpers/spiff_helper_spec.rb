describe Bosh::Workspace::SpiffHelper do
  describe ".spiff" do
    class SpiffHelperTester
      include Bosh::Workspace::SpiffHelper
    end
    subject { SpiffHelperTester.new }
    let(:path) { asset_dir("bin") }
    let(:templates) { ["foo.yml", "bar.yml"] }
    let(:target_file) { "spiffed_manifest.yml" }

    around do |example|
      original_path = ENV["PATH"]
      ENV["PATH"] = path
      example.run
      ENV["PATH"] = original_path
    end

    before do
      subject.should_receive(:sh).and_yield(result)
    end

    context "spiff not in path" do
      let(:path) { asset_dir("empty_bin") }
      let(:result) { Bosh::Exec::Result.new("spiff", "", 0, true) }

      it "raises an error" do
        expect{ subject.spiff_merge templates, target_file }
          .to raise_error /make sure spiff is installed/
      end
    end

    context "spiff error" do
      let(:path) { asset_dir("empty_bin") }
      let(:result) { Bosh::Exec::Result.new("spiff", "spiff error", 1, false) }

      it "raises an error" do
        subject.should_receive(:say).with(/Command failed/)
        expect{ subject.spiff_merge templates, target_file }
          .to raise_error /spiff error/
      end
    end

    describe ".merge" do
      let(:file) { instance_double("File") }
      let(:output) { "---\n{}" }
      let(:result) { Bosh::Exec::Result.new("spiff", output, 0, false) }

      it "merges manifests" do
        File.should_receive(:open).with(target_file, 'w').and_yield(file)
        file.should_receive(:write).with(output)
        subject.spiff_merge templates, target_file
      end
    end
  end
end
