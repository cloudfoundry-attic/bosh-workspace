describe Bosh::Workspace::SpiffHelper do
  describe ".spiff" do
    class SpiffHelperTester
      include Bosh::Workspace::SpiffHelper
    end
    subject { SpiffHelperTester.new }
    let(:path) { asset_dir("bin") }
    let(:templates) { ["foo.yml", "bar.yml"] }
    let(:target_file) { "spiffed_manifest.yml" }
    let(:args) { [/spiff merge/, Hash] }

    around do |example|
      original_path = ENV["PATH"]
      ENV["PATH"] = path
      example.run
      ENV["PATH"] = original_path
    end

    before do
      expect(subject).to receive(:sh).with(*args).and_yield(result)
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
        expect(subject).to receive(:say).with(/Command failed/)
        expect{ subject.spiff_merge templates, target_file }
          .to raise_error /spiff error/
      end
    end

    describe ".spiff_merge" do
      let(:file) { instance_double("File") }
      let(:output) { "---\n{}" }
      let(:result) { Bosh::Exec::Result.new("spiff", output, 0, false) }

      before do
        expect(File).to receive(:open).with(target_file, 'w').and_yield(file)
        expect(file).to receive(:write).with(output)
      end

      it "merges manifests" do
        subject.spiff_merge templates, target_file
      end

      context "spaces in template paths" do
        let(:templates) { ["space test/foo space test.yml"] }
        let(:args) { [/space\\ test\/foo\\ space\\ test.yml/, Hash] }

        it "merges manifests" do
          subject.spiff_merge templates, target_file
        end
      end
    end
  end
end
