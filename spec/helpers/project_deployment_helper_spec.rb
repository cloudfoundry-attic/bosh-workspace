describe Bosh::Manifests::ProjectDeploymentHelper do
  class HelperTester
    include Bosh::Manifests::ProjectDeploymentHelper

    attr_reader :director, :deployment

    def initialize(director, deployment, project_deployment = nil)
      @director = director
      @deployment = deployment
      @project_deployment = project_deployment
    end
  end

  subject { project_deployment_helper }
  let(:project_deployment_helper) { HelperTester.new(director, deployment) }
  let(:deployment) { nil }
  let(:director) { instance_double('Bosh::Cli::Client::Director') }
  let(:work_dir) { asset_dir("manifests-repo") }
  let(:project_deployment) { instance_double("DeploymentManifest") }

  describe "project_deployment?" do
    subject { project_deployment_helper.project_deployment? }
    let(:deployment) { File.join work_dir, deployment_path }

    context "deployment" do
      context "without associated project deployment" do
        let(:deployment_path) { "deployments/bar.yml" }
        it { should be_false }
      end
      context "with associated project deployment" do
        let(:deployment_path) { ".manifests/foo.yml" }
        it { should be_true }
      end
    end

    context "project deployment" do
      let(:deployment_path) { "deployments/foo.yml" }
      it { should be_true }
    end
  end

  describe "#project_deployment(=)" do
    let(:deployment) { File.join work_dir, deployment_path }
    let(:deployment_path) { "deployments/foo.yml" }

    before do
      Bosh::Manifests::DeploymentManifest.should_receive(:new)
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
      it { should be_true }
    end

    context "normal deployment" do
      let(:content) { { "name" => "foo" } }
      it { should be_false }
    end
  end

  describe "#require_project_deployment" do
    before do
      subject.should_receive(:project_deployment?)
        .and_return(:is_project_deployment)
    end

    context "project deployment" do
      let(:is_project_deployment) { true }
      it "validates & builds" do
        subject.should_receive(:validate_project_deployment)
        subject.should_receive(:build_project_deployment)
        subject.require_project_deployment
      end
    end

    context "normal deployment" do
      let(:deployment) { "foo" }
      let(:is_project_deployment) { false }
      it "raises and error" do
        expect { subject.require_project_deployment }.to raise_error /foo/
      end
    end
  end

  describe "#validate_project_deployment" do
    let(:project_deployment_helper) do
      HelperTester.new(director, deployment, project_deployment)
    end

    it "raises an error" do
      project_deployment.should_receive(:valid?).and_return(false)
      project_deployment.should_receive(:errors).and_return(["foo"])
      project_deployment.should_receive(:file).and_return(["foo.yml"])
      expect { subject.validate_project_deployment }.to raise_error /foo/
    end
  end

  describe "#build_project_deployment" do
    subject { project_deployment_helper.build_project_deployment }
    let(:project_deployment_helper) do
      HelperTester.new(director, deployment, project_deployment)
    end
    let(:status) { { "uuid" => current_uuid, "cpi" => cpi } }
    let(:current_uuid) { "current-uuid" }

    before do
      project_deployment.should_receive(:director_uuid).and_return(uuid)
      director.stub(:get_status).and_return(status)
    end

    context "using the warden cpi" do
      let(:cpi) { "warden" }

      before do
        project_deployment_helper.should_receive(:work_dir).and_return(work_dir)
        Bosh::Manifests::ManifestBuilder.should_receive(:build)
          .with(project_deployment, work_dir)
      end

      context "with director uuid current" do
        let(:uuid) { "current" }
        it "builds manifest" do
          project_deployment.should_receive(:director_uuid=).with(current_uuid)
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

    context "and without warden cpi" do
      let(:uuid) { "current" }
      let(:cpi) { "not-warden" }
      it "raises an error" do
        expect { subject }.to  raise_error /may not be used in production/
      end
    end
  end
end
