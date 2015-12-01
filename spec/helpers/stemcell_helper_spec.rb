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

    describe "#stemcell_download" do
      let(:stemcell) { instance_double("Bosh::Workspace::Stemcell", :name => "foo", :version => "1") }

      subject { stemcell_helper.stemcell_download(stemcell) }

      it "downloads stemcell" do
        expect(Dir).to receive(:chdir).and_yield
        expect(stemcell_helper).to receive(:download_stemcell_from_bosh_io).with(stemcell)
        subject
      end
    end

    describe "#stemcell_upload" do
      let(:file) { "foo.tgz" }
      subject { stemcell_helper.stemcell_upload(file) }

      it "uploads stemcell" do
        expect(stemcell_cmd).to receive(:upload).with(file)
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

  describe "#stemcell_dir" do
    let(:stemcells_dir) { File.join(work_dir, ".stemcells") }
    subject { stemcell_helper.stemcells_dir }

    before do
      expect(FileUtils).to receive(:mkdir_p).once.with(stemcells_dir)
        .and_return([stemcells_dir])
    end

    it { should eq stemcells_dir }

    it "memoizes" do
      subject
      expect(subject).to eq stemcells_dir
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
        .with(stemcell_data, /\/.stemcells/).and_return(stemcell)
      subject
      expect(subject).to eq [stemcell, stemcell]
    end
  end
end
