describe Bosh::Workspace::DnsHelper do
  describe ".transform" do
    subject do
      Bosh::Workspace::DnsHelper.transform(generated_manifest, domain_name)
      YAML.load(IO.read(generated_manifest))
    end

    let(:generated_manifest) { get_tmp_file_path(content) }
    let(:domain_name) { "microbosh" }

    context "networks" do
      let(:content) { asset_file("dns/networks-manual.yml") }

      it "replaces manual networks" do
        expect(subject["networks"][1]["type"]).to eq "dynamic"
      end
    end

    context "no manual networks" do
      let(:content) { asset_file("dns/networks-no-manual.yml") }

      it "raises an error" do
        expect { subject }.to raise_error /Missing manual network/
      end
    end

    context "jobs" do
      let(:content) { asset_file("dns/jobs.yml") }

      it "removes static_ips of jobs with manual networks" do
        expect(subject["jobs"][0]["networks"][0]).to_not include "static_ips"
        expect(subject["jobs"][1]["networks"][0]).to_not include "static_ips"
      end
    end

    context "properties" do
      let(:content) { asset_file("dns/properties.yml") }

      it "replaces ips with domains while keeping properties structure" do
        expect(subject["properties"]["job1"]["address"])
          .to eq "0.first-job-az1.default.foo.microbosh"
        expect(subject["properties"]["job1"]["foo"]).to eq "bar"
        expect(subject["properties"]["job2"]["machines"])
          .to eq ["0.second-job-az1.default.foo.microbosh",
                  "1.second-job-az1.default.foo.microbosh"]
      end
    end

    context "job properties" do
      let(:content) { asset_file("dns/job-properties.yml") }

      it "replaces ips with domains while keeping properties structure" do
        expect(subject["jobs"][1]["properties"]["job1"]["address"])
          .to eq "0.first-job-az1.default.foo.microbosh"
        expect(subject["jobs"][1]["properties"]["job1"]["foo"]).to eq "bar"
      end
    end
  end
end
