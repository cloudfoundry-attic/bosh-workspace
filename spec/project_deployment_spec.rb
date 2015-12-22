module Bosh::Workspace
  describe ProjectDeployment do
    subject { Bosh::Workspace::ProjectDeployment.new manifest_file }
    let(:manifest_content) { manifest.to_yaml }
    let(:manifest_file) { get_tmp_file_path(manifest_content, file_name) }
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

    describe '#manifest' do
      context 'with stub file' do
        let!(:stub_file) do
          path = "../../stubs/#{stub_filename}"
          File.expand_path(path, manifest_file).tap do |file|
            FileUtils.mkdir_p File.dirname(file)
            IO.write(file, stub_content)
          end
        end

	after { FileUtils.rm(stub_file) }

        let(:stub_filename) { File.basename(manifest_file) }

        let(:manifest) { { 'director_uuid' => 'DIRECTOR_UUID' } }
        let(:stub_content) do
          {
            'name' => 'bar',
            'director_uuid' => 'foo-uuid',
            'meta' => { 'foo' => 'bar' }
          }.to_yaml
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
        let(:stub_file) { asset_dir("manifests-repo/stubs/foobar.sh") }
        let(:manifest_file) { asset_dir("manifests-repo/deployments/foobar.yml") }
        let(:manifest) do
          {
            'name' => 'NAME',
            'director_uuid' => 'DIRECTOR_UUID',
            'meta' =>  { 'foo' => 'bar', 'bar' => 'foo' }
          }
        end

        it 'merges stub output with manifest' do
          expect(subject.manifest['name']).to eq('foobar')
          expect(subject.manifest['director_uuid']).to eq('bar-uuid')
          expect(subject.manifest['meta']).to eq({ 'foo' => 'foobar', 'bar' => 'foo' })
        end


        context 'which are invalid' do
          let(:result) { Bosh::Exec::Result.new('foo.sh', 'foo: error:', exit_code) }
          
          before do
            expect(subject).to receive(:sh).and_yield(result).and_return(result)
          end

          context 'non valid yaml returned' do
            let(:exit_code) { 0 }
            
            it 'raises an error' do 
              expect{ subject.manifest }.to raise_error /mapping values are not allowed/
            end
          end

          context 'failure during execution' do
            let(:exit_code) { 1 }
            
            it 'raises an error' do 
              expect{ subject.manifest }.to raise_error /foo: error/
            end
          end
        end
      end

      context 'without stub file' do
        let(:file_name) { 'bar.yml' }
        let(:manifest) { { 'director_uuid' => 'litmus' } }

        it 'reads manifest without errors' do
          expect(subject.manifest['director_uuid']).to eq('litmus')
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
