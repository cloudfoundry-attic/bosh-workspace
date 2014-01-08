describe Bosh::Manifests::SpiffHelper do
  describe ".spiff" do
    class SpiffHelperTester
      include Bosh::Manifests::SpiffHelper
    end
    subject { SpiffHelperTester.new }

    it "creates a SpiffCommand" do
      expect(subject.spiff).to be_instance_of(Bosh::Manifests::SpiffCommand)
    end
  end
end

describe Bosh::Manifests::SpiffCommand do
  let(:spiff_command) { Bosh::Manifests::SpiffCommand.new }
  subject { spiff_command }
  let(:path) { asset_dir("bin") }
  let(:templates) { ["foo.yml", "bar.yml"] }
  let(:target_file) { "spiffed_manifest.yml" }

  before do
    ENV["PATH"] = path
  end

  context "spiff not in path" do
    subject { lambda { spiff_command.merge templates, target_file } }
    let(:path) { asset_dir("empty_bin") }
    it { should raise_error /make sure spiff is installed/ }
  end

  describe ".merge" do
    let(:file) { instance_double("File") }
    let(:output) { "---\n{}" }
    let(:result) { Bosh::Exec::Result.new("spiff", output, 0, false) }

    it "merges manifests" do
      subject.should_receive(:sh).and_yield(result)
      File.should_receive(:open).with(target_file, 'w').and_yield(file)
      file.should_receive(:write).with(output)
      subject.merge templates, target_file
    end
  end
end
