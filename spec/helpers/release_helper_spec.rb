describe Bosh::Workspace::ReleaseHelper do
  class ReleaseHelperTester
    include Bosh::Workspace::ReleaseHelper

    attr_reader :director, :work_dir

    def initialize(director, work_dir)
      @director = director
      @work_dir = work_dir
    end
  end

  subject { release_helper }
  let(:release_helper) { ReleaseHelperTester.new(director, work_dir) }
  let(:director) { instance_double('Bosh::Cli::Client::Director') }
  let(:work_dir) { asset_dir("manifests-repo") }

  describe "#release_upload" do
    let(:release_cmd) { instance_double("Bosh::Cli::Command::Release") }
    before { Bosh::Cli::Command::Release.stub(:new).and_return(release_cmd) }
    
    let(:manifest_file) { "foo-1.yml." }
    subject { release_helper.release_upload(manifest_file) }
      
    it "uploads release" do
      release_cmd.should_receive(:upload).with(manifest_file)
      subject
    end
  end

  describe "#release_uploaded?" do
    let(:releases) { { "versions" => %w(1 2 3) } }
    subject { release_helper.release_uploaded?("foo", version) }
    before { director.should_receive(:get_release).with("foo").and_return(releases) }

    context "release exists" do
      let(:version) { 2 }
      it { should be_true }
    end

    context "release not found" do
      let(:version) { "8" }
      it { should be_false }
    end
  end
  
  describe "#release_dir" do
    let(:releases_dir) { File.join(work_dir, ".releases") }
    subject { release_helper.releases_dir }
    
    before { FileUtils.should_receive(:mkdir_p).once.with(releases_dir).and_return([releases_dir]) }

    it { should eq releases_dir }

    it "memoizes" do
      subject
      expect(subject).to eq releases_dir
    end
  end
end
