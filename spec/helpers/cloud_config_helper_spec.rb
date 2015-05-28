describe Bosh::Workspace::DnsHelper do
  describe ".transform" do
    subject do
      Bosh::Workspace::CloudConfigHelper.transform(generated_manifest, networks)
      YAML.load(IO.read(generated_manifest))
    end

    let(:generated_manifest) { get_tmp_file_path(content) }
    let(:networks) { [{ 'name' => 'default', 'rename' => 'shared' }] }
    let(:content) { asset_file("cloud_config/manifest.yml") }

    context "networks" do
      it "renames networks" do
        expect(subject["jobs"][0]["networks"][0]["name"]).to eq "shared"
      end
    end

    context "manifest" do
      it "filters manifest" do
        expect(subject.keys.sort)
          .to eq %w(director_uuid jobs name properties releases update)
      end
    end
  end
end
