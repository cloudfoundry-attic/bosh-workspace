describe Bosh::Workspace::StemcellHelper do
  class StemcellHelperTester
    include Bosh::Workspace::StemcellHelper

    attr_reader :director, :work_dir

    def initialize(director, work_dir)
      @director = director
      @work_dir = work_dir
    end
  end

  subject { stemcell_helper }
  let(:stemcell_helper) { StemcellHelperTester.new(director, work_dir) }
  let(:director) { instance_double('Bosh::Cli::Client::Director') }
  let(:work_dir) { asset_dir("manifests-repo") }

  context "with stemcell command" do
    let(:stemcell_cmd) { instance_double("Bosh::Cli::Command::Stemcell") }
    before do
      allow(Bosh::Cli::Command::Stemcell)
        .to receive(:new).and_return(stemcell_cmd)
    end


    describe "#stemcell_upload_url" do
      let(:url) { "http://foo" }
      subject { stemcell_helper.stemcell_upload_url(url) }

      it "uploads stemcell" do
        expect(stemcell_cmd).to receive(:upload).with(url)
        subject
      end
    end
  end

  describe "#stemcell_uploaded?" do
    let(:stemcells) { [{ "name" => "foo", "version" => "1" }] }
    subject { stemcell_helper.stemcell_uploaded?(name, 1) }
    before do
      expect(director).to receive(:list_stemcells).and_return(stemcells)
    end

    context "stemcell exists" do
      let(:name) { "foo" }
      it { should be true }
    end

    context "stemcell not found" do
      let(:name) { "bar" }
      it { should be false }
    end
  end

  describe "#project_deployment_stemcells" do
    subject { stemcell_helper.project_deployment_stemcells }
    let(:stemcell) { instance_double("Bosh::Workspace::Stemcell") }
    let(:stemcell_data) { { name: "foo" } }
    let(:stemcells) { [stemcell_data, stemcell_data] }

    before do
      allow(stemcell_helper)
        .to receive_message_chain("project_deployment.stemcells")
        .and_return(stemcells)
    end

    it "inits stemcells once" do
      expect(Bosh::Workspace::Stemcell).to receive(:new).twice
        .with(stemcell_data).and_return(stemcell)
      subject
      expect(subject).to eq [stemcell, stemcell]
    end
  end
end
