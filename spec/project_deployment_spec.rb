module Bosh::Workspace
  describe ProjectDeployment do
    subject { Bosh::Workspace::ProjectDeployment.new manifest_file }
    let(:manifest_file) { get_tmp_file_path(manifest.to_yaml, file_name) }
    let(:file_name) { "foo.yml" }
    let(:manifest) { :manifest }

    describe ".new" do
      context "deployment file does not exist" do
        before do
          allow(File).to receive(:exist?).with(manifest_file).and_return(false)
        end
        it { expect { subject }.to raise_error(/deployment file.+not exist/i) }
      end
    end

    describe "#perform_validation" do
      context "valid" do
        it "validates" do
          allow_any_instance_of(Schemas::ProjectDeployment)
            .to receive(:validate).with(manifest)
          expect(subject).to be_valid
        end
      end

      context "invalid" do
        it "has errors" do
          allow_any_instance_of(Schemas::ProjectDeployment)
            .to receive(:validate).with(manifest)
            .and_raise(Membrane::SchemaValidationError.new("foo"))
          expect(subject).to_not be_valid
          expect(subject.errors).to include "foo"
        end
      end
    end

    describe "#director_uuid=" do
      before { subject.director_uuid = "foo-bar" }
      its(:director_uuid) { should eq "foo-bar" }
    end

    describe "attr readers" do
      let(:manifest) { {
          "name" => :name,
          "director_uuid" => :director_uuid,
          "templates" => :templates,
          "releases" => :releases,
          "stemcells" => :stemcells,
          "meta" => :meta,
          "domain_name" => :domain_name,
        } }

      let(:director_uuid) { uuid }
      %w(name director_uuid templates releases stemcells meta domain_name)
        .each do |attr|
        its(attr.to_sym) { should eq attr.to_sym }
      end
    end

    describe "#merged_file" do
      it "creates parent directory" do
        dir = File.dirname(subject.merged_file)
        expect(File.directory?(dir)).to be true
      end

      it "retruns merged file" do
        expect(subject.merged_file).to match(/\.deployments\/#{file_name}/)
      end
    end
  end
end
