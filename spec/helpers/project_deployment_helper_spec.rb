describe Bosh::Workspace::ProjectDeploymentHelper do
  class ProjectDeploymentHelperTester
    include Bosh::Workspace::ProjectDeploymentHelper

    attr_reader :director, :deployment

    def initialize(director, deployment, project_deployment = nil)
      @director = director
      @deployment = deployment
      @project_deployment = project_deployment
    end
  end

  subject { project_deployment_helper }
  let(:project_deployment_helper) do
    ProjectDeploymentHelperTester.new(director, deployment, project_deployment)
  end
  let(:deployment) { nil }
  let(:director) { instance_double('Bosh::Cli::Client::Director') }
  let(:work_dir) { asset_dir("manifests-repo") }
  let(:project_deployment) { instance_double("ProjectDeployment") }

  describe "project_deployment?" do
    subject { project_deployment_helper.project_deployment? }
    let(:project_deployment_helper) { ProjectDeploymentHelperTester.new(director, deployment) }
    let(:deployment) { File.join(work_dir, deployment_path) }

    context "deployment" do
      context "without associated project deployment" do
        let(:deployment_path) { "deployments/bar.yml" }
        it { should be false }
      end
      context "with associated project deployment" do
        let(:deployment_path) { ".manifests/foo.yml" }
        it { should be true }
      end
    end

    context "project deployment" do
      let(:deployment_path) { "deployments/foo.yml" }
      it { should be true }
    end
  end

  describe "#project_deployment(=)" do
    let(:project_deployment_helper) { ProjectDeploymentHelperTester.new(director, deployment) }
    let(:deployment) { File.join work_dir, deployment_path }
    let(:deployment_path) { "deployments/foo.yml" }

    before do
      expect(Bosh::Workspace::ProjectDeployment).to receive(:new)
        .with(deployment).and_return(project_deployment)
    end

    it "loads deployment manifest" do
      expect(subject.project_deployment).to eq project_deployment
    end

    it "memoizes deployment manifest" do
      subject.project_deployment = deployment
      expect(subject.project_deployment).to eq project_deployment
    end
  end

  describe "#project_deployment_file?" do
    subject do
      project_deployment_helper.project_deployment_file? deployment_file
    end
    let(:deployment_file) { get_tmp_file_path(content.to_yaml) }

    context "project deployment" do
      let(:content) { { "name" => "foo", "templates" => ["bar.yml"] } }
      it { should be true }
    end

    context "normal deployment" do
      let(:content) { { "name" => "foo" } }
      it { should be false }
    end
  end

  describe "#require_project_deployment" do
    let(:project_deployment_helper) { ProjectDeploymentHelperTester.new(director, deployment) }

    before do
      allow(subject).to receive(:project_deployment?)
        .and_return(:is_project_deployment)
    end

    context "no deployment is set" do
      let(:deployment) { nil }

      it "raises an help full error" do
        expect{ subject.require_project_deployment }
          .to raise_error /no deployment set/i
      end
    end

    context "project deployment" do
      let(:is_project_deployment) { true }
      let(:deployment) { '.deployment/foo.yml' }

      it "validates & builds" do
        expect(subject).to receive(:validate_project_deployment)
        subject.require_project_deployment
      end
    end

    context "normal deployment" do
      let(:deployment) { "foo" }
      let(:is_project_deployment) { false }
      it "raises and error" do
        expect { subject.require_project_deployment }.to raise_error(/foo/)
      end
    end
  end

  describe "#create_placeholder_deployment" do
    subject { project_deployment_helper.create_placeholder_deployment }
    let(:deployment) { "deployments/bar.yml" }
    let(:file) { instance_double('File') }
    let(:merged_file) { ".deployments/bar.yml" }
    let(:uuid) { "8451a282-4073" }
    let(:content) { "director_uuid #{uuid}" }

    it "creates placeholder deployment" do
      expect(project_deployment_helper).to receive(:resolve_director_uuid)
      expect(project_deployment).to receive(:merged_file).and_return(merged_file)
      expect(project_deployment).to receive(:file).and_return(deployment)
      expect(project_deployment).to receive(:director_uuid).and_return(uuid)
      expect(File).to receive(:open).with(merged_file, "w").and_yield(file)
      expect(file).to receive(:write).with(/#{uuid}\s# Don't edit/)
      subject
    end
  end

  describe "#validate_project_deployment" do
    it "raises an error" do
      expect(project_deployment).to receive(:valid?).and_return(false)
      expect(project_deployment).to receive(:errors).and_return(["foo"])
      expect(project_deployment).to receive(:file).and_return(["foo.yml"])
      expect { subject.validate_project_deployment }.to raise_error(/foo/)
    end
  end

  describe "#build_project_deployment" do
    subject { project_deployment_helper.build_project_deployment }
    let(:domain_name) { "bosh" }
    let(:merged_file) { "foo/bar" }

    it "builds project deployment manifest" do
      expect(project_deployment_helper).to receive(:resolve_director_uuid)
      expect(project_deployment_helper).to receive(:work_dir)
        .and_return(work_dir)
      expect(project_deployment).to receive(:domain_name)
        .and_return(domain_name)
      expect(project_deployment).to receive(:merged_file)
        .and_return(merged_file)

      expect(Bosh::Workspace::ManifestBuilder).to receive(:build)
        .with(project_deployment, work_dir)
      expect(Bosh::Workspace::DnsHelper).to receive(:transform)
        .with(merged_file, domain_name)

      subject
    end
  end

  describe "#resolve_director_uuid" do
    subject { project_deployment_helper.resolve_director_uuid }
    let(:status) { { "uuid" => current_uuid, "cpi" => cpi, "name" => director_name } }
    let(:current_uuid) { "current-uuid" }
    let(:director_name) { "foobar" }

    before do
      expect(project_deployment).to receive(:director_uuid).and_return(uuid)
      allow(director).to receive(:get_status).and_return(status)
    end

    context "using the warden cpi" do
      let(:cpi) { "warden" }

      context "with director uuid current" do
        let(:uuid) { "current" }
        it "builds manifest" do
          expect(project_deployment).to receive(:director_uuid=).with(current_uuid)
          subject
        end
      end

      context "with director uuid" do
        let(:uuid) { "8451a282-4073" }
        it "builds manifest" do
          subject
        end
      end
    end

    context "using the warden cpi which is now called vsphere" do
      let(:cpi) { "vsphere" }
      let(:director_name) { "Bosh Lite Director" }

      context "with director uuid current" do
        let(:uuid) { "current" }
        it "builds manifest" do
          expect(project_deployment).to receive(:director_uuid=).with(current_uuid)
          subject
        end
      end
    end

    context "and without warden cpi" do
      let(:uuid) { "current" }
      let(:cpi) { "not-warden" }
      it "raises an error" do
        expect { subject }.to  raise_error(/may not be used in production/)
      end
    end
  end

  describe "#offline!" do
    it "enforces offline mode" do
      subject.offline!
      expect(subject.offline?).to eq(true)
    end

    it "defaults to online" do
      expect(subject.offline?).to eq(nil)
    end
  end
end
