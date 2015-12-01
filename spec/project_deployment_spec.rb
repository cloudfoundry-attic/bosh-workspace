module Bosh::Workspace
  describe ProjectDeployment do
    subject { Bosh::Workspace::ProjectDeployment.new manifest_file }
    let(:manifest_content) { ruby_code + manifest.to_yaml }
    let(:manifest_file) { get_tmp_file_path(manifest_content, file_name) }
    let(:file_name) { "foo.yml" }
    let(:manifest) { :manifest }
    let(:ruby_code) { "<% ruby_var=42 %>" }

    describe ".new" do
      context "deployment file does not exist" do
        before do
          allow(File).to receive(:exist?).with(manifest_file).and_return(false)
        end
        it { expect { subject }.to raise_error(/deployment file.+not exist/i) }
      end
    end

    describe '#manifest' do
      let(:stub_file) { /stubs\/#{file_name}/ }
      before do
        allow(File).to receive(:exist?).with(manifest_file).and_return(true)
        allow(File).to receive(:read).with(manifest_file).and_return(manifest_content)
      end

      context 'with stub file' do
        let(:manifest) { { 'director_uuid' => 'DIRECTOR_UUID' } }
        let(:stub_content) do
          {
            'name' => 'bar',
            'director_uuid' => 'foo-uuid',
            'meta' => { 'foo' => 'bar' }
          }.to_yaml
        end

        before do
          allow(File).to receive(:exist?).with(stub_file).and_return(true)
          allow(File).to receive(:read).with(stub_file).and_return(stub_content)
        end

        it 'merges stub with manifest' do
          expect(subject.manifest['director_uuid']).to eq('foo-uuid')
        end

        context 'stub with releases' do
          let(:stub_content) { { 'releases' => [] }.to_yaml }

          it 'raises an error' do
            expect{ subject.manifest }.to raise_error /releases.+not allowed/
          end
        end
      end

      context 'with executable stub file' do
        let(:manifest) do
          {
            'name' => 'NAME',
            'director_uuid' => 'DIRECTOR_UUID',
            'meta' =>  { 'foo' => 'bar', 'bar' => 'foo' }
          }
        end
        let(:stub_output) do
          "name: bar\ndirector_uuid: bar-uuid\nmeta:\n  foo: foobar\n"
        end

        before do
          allow(File).to receive(:exist?).with(stub_file).and_return(true)
          allow(File).to receive(:executable?).with(stub_file).and_return(true)
          allow_any_instance_of(Bosh::Workspace::ProjectDeployment)
          .to receive(:execute_stub).with(stub_file).and_return(stub_output)
        end

        it 'merges stub output with manifest' do
          expect(subject.manifest['name']).to eq('bar')
          expect(subject.manifest['director_uuid']).to eq('bar-uuid')
          expect(subject.manifest['meta']).to eq({ 'foo' => 'foobar', 'bar' => 'foo' })
        end
      end

      context 'without stub file' do
        let(:manifest) { { 'director_uuid' => 'litmus' } }

        before do
          allow(File).to receive(:exist?).with(stub_file).and_return(false)
        end

        it 'reads manifest without errors' do
          expect(subject.manifest['director_uuid']).to eq('litmus')
        end
      end
    end

    describe "#load_stub" do
      context "executable file" do
        let(:stub_file) { asset_dir("manifests-repo/stubs/foobar.sh") }

        it "returns output as yaml" do
          expect(subject.load_stub(stub_file)).to eq({ "name" => "foobar" })
        end
      end

      context "normal file" do
        let(:stub_file) { asset_dir("manifests-repo/stubs/foo.yml") }

        it "returns content as yaml" do
          expect(subject.load_stub(stub_file)).to eq({ 
            "meta" => { "stub" => { "value" => "value" }}
          })
        end
      end
    end

    describe "#execute_stub" do
      context "executable file" do
        let(:stub_file) { asset_dir("manifests-repo/stubs/foobar.sh") }

        it "returns output" do
          expect(subject.execute_stub(stub_file)).to eq('name: foobar')
        end
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
