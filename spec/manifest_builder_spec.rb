describe Bosh::Workspace::ManifestBuilder do
  let(:project_deployment) { instance_double("Bosh::Workspace::Project_Deployment",
    name: "bar",
    templates: ["foo.yml"],
    merged_file: ".deployments/foo.yml",
    merge_tool: Bosh::Workspace::MergeTool.new)
  }
  let(:work_dir) { asset_dir("manifests-repo") }

  describe ".build" do
    subject { Bosh::Workspace::ManifestBuilder.build project_deployment, work_dir }
    let(:manifest_builder) {
      instance_double("Bosh::Workspace::ManifestBuilder") }

    it "creates builder and merges templates" do
      expect(Bosh::Workspace::ManifestBuilder).to receive(:new)
        .with(project_deployment, work_dir).and_return(manifest_builder)
      expect(manifest_builder).to receive(:merge_templates)
      subject
    end
  end

  describe "#merge_templates" do
    subject { Bosh::Workspace::ManifestBuilder.new(project_deployment, work_dir) }

    before do
      allow(File).to receive(:exists?).with(/templates\//)
        .and_return(template_exists)
    end

    context "missing template" do
      let(:template_exists) { false }
      it "raises error" do
        expect { subject.merge_templates }.to raise_error(/does not exist/)
      end
    end

    context "template exists" do
      let(:template_exists) { true }
      let(:dir_exists) { true }

      before do
        allow(File).to receive(:exists?).with(/\.stubs/).and_return(dir_exists)
        expect(Bosh::Workspace::StubFile).to receive(:create)
          .with(/\.stubs\/.+yml/, project_deployment)
      end

      context "no hidden dirs" do
        let(:dir_exists) { false }
        it "creates hidden dirs" do
          expect(subject.merge_tool).to receive(:merge)
          expect(Dir).to receive(:mkdir).with(/.stubs/)
          subject.merge_templates
        end
      end

      it "generates manifest with spiff" do
          expect(subject.merge_tool).to receive(:merge) do |args|
          if args.is_a?(Array)
            expect(args.first).to match(/\/templates\/.+yml/)
            expect(args.last).to match(/\.stubs\/.+yml/)
          else
            expect(args).to match(/\.deployments\/.+yml/)
          end
        end
        subject.merge_templates
      end
    end
  end
end
