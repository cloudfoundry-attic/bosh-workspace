describe Bosh::Manifests::ManifestBuilder do
  let(:manifest) { instance_double("Bosh::Manifests::Manifest") }
  let(:work_dir) { asset_dir("manifests-repo") }
  let(:target_name) { "bar" }
  let(:target_file) {
    File.join(work_dir, ".manifests", "#{target_name}.yml") }

  describe ".build" do
    subject { Bosh::Manifests::ManifestBuilder.build manifest, work_dir }
    let(:manifest_builder) {
      instance_double("Bosh::Manifests::ManifestBuilder") }

    it "creates builder and merges templates" do
      Bosh::Manifests::ManifestBuilder.should_receive(:new)
        .with(manifest, work_dir).and_return(manifest_builder)
      manifest_builder.should_receive(:merge_templates)
        .and_return(target_file)
      expect(subject).to eq target_file
    end
  end

  describe "#merge_templates" do
    subject { Bosh::Manifests::ManifestBuilder.new manifest, work_dir }
    let(:templates) { ["foo.yml"] }
    let(:template_path) { File.join(work_dir, "templates/foo.yml") }
    let(:template_exists) { true }

    before do
      manifest.should_receive(:templates).and_return(templates)
      File.should_receive(:exists?).with(template_path)
        .and_return(template_exists)
    end

    context "missing template" do
      let(:template_exists) { false }
      it "raises error" do
        expect{ subject.merge_templates }.to raise_error /does not exist/
      end
    end

    context "template exists" do
      let(:dir_exists) { true }
      let(:target_dir) { File.join(work_dir, ".manifests" ) }
      let(:meta_file_path) {
        File.join(work_dir, ".meta", "#{target_name}.yml") }
      let(:meta_file) { instance_double("File") }
      let(:meta) { { "foo" => "bar" } }

      before do
        manifest.should_receive(:name).twice.and_return(target_name)
        manifest.should_receive(:meta).and_return(meta)
        File.should_receive(:exists?).twice.and_return(dir_exists)
        File.should_receive(:open).with(meta_file_path, "w")
          .and_yield(meta_file)
        meta_file.should_receive(:write).with({ "meta" => meta }.to_yaml)
      end

      context "no hidden dirs" do
        let(:dir_exists) { false }
        it "creates hidden dirs" do
          subject.stub(:spiff_merge)
          Dir.should_receive(:mkdir).with(/.meta/)
          Dir.should_receive(:mkdir).with(/.manifests/)
          subject.merge_templates
        end
      end

      it "generates manifest with spiff" do
        subject.should_receive(:spiff_merge)
          .with([template_path, meta_file_path], target_file)
        subject.merge_templates
      end
    end
  end
end
