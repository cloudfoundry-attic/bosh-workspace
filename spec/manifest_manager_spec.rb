describe Bosh::Manifests::ManifestManager do
  let(:manifest_manager) { Bosh::Manifests::ManifestManager.discover work_dir }
  let(:work_dir) { asset_dir("manifests-repo") }
  let(:manifest_file) { File.join(work_dir, "manifests", manifest_filename) }
  let(:manifest_filename) { "foo.yml" }
  let(:name) { "foo" }

  subject { manifest_manager }

  describe ".discover" do
    context "no manifests dir" do
      subject { lambda { manifest_manager } }
      let(:work_dir) { asset_dir("empty-manifests-repo") }
      it { should raise_error Bosh::Cli::CliError }
    end

    context "manifests dir exists" do
      it "initializes manifests" do
        Bosh::Manifests::Manifest.should_receive(:new).with(manifest_file)
        expect(subject).to be_instance_of(Bosh::Manifests::ManifestManager)
      end
    end
  end

  context "with manifest" do
    let(:manifest) { instance_double("Bosh::Manifests::Manifest") }
    before do
      Bosh::Manifests::Manifest.stub(:new).and_return(manifest)
    end


    describe "#validate_manifests" do
      it "performs validations" do
        manifest.should_receive(:filename).and_return(manifest_filename)
        manifest.should_receive(:valid?).and_return(false)
        manifest.should_receive(:errors).and_return(["error1", "error2"])
        subject.should_receive(:say).with("Validation errors:")
        subject.should_receive(:say).with("- error1")
        subject.should_receive(:say).with("- error2")
        expect{subject.validate_manifests}.to raise_error /not a valid manifest/
      end
    end

    describe "#to_table" do
      subject { manifest_manager.to_table.to_s }

      it "returns a table" do
        manifest.should_receive(:name).and_return(name)
        manifest.should_receive(:filename).and_return(manifest_filename)
        expect(subject).to include name
        expect(subject).to include manifest_filename
      end
    end

    describe "#find" do
      before do
        manifest.should_receive(:name).and_return(name)
      end

      context "name not known" do
        it "raise an error" do
          expect{subject.find("bar")}.to raise_error /Could not find manifest/
        end
      end

      context "name kown" do
        it "finds manifest" do
          expect(subject.find(name)).to eq manifest
        end
      end
    end
  end
end
