describe Bosh::Manifests::DnsHelper do
  describe ".transform" do
    subject { YAML.load(IO.read(generated_manifest)) }
    let(:generated_manifest) { get_tmp_file_path(content) }
    let(:domain_name) { "microbosh" }

    before do
      Bosh::Manifests::DnsHelper.transform(generated_manifest, domain_name)
    end

    context "networks" do
      let(:content) { asset_file("dns/networks-openstack.yml") }
      
      it "replaces" do
        expect(subject["networks"][1]["type"]).to eq "dynamic"
      end
    end
  end
end
