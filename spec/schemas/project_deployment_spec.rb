module Bosh::Workspace::Schemas
  describe ProjectDeployment do
    before do
      allow_any_instance_of(Releases).to receive(:validate).with(:releases)
      allow_any_instance_of(Stemcells).to receive(:validate).with(:stemcells)
    end

    let(:project_deployment) do
      {
        "name" => "foo",
        "director_uuid" => "e55134c3-0a63-47be-8409-c9e53e965d5c",
        "stemcells" => :stemcells,
        "releases" => :releases,
        "templates" => [ "foo/bar.yml" ],
        "meta" => { "foo" => "bar" }
      }
    end

    subject { ProjectDeployment.new.validate(project_deployment) }

    %w(name director_uuid releases templates meta stemcells).each do |field|
      context "missing #{field}" do
        before { project_deployment.delete field }
        it { expect { subject }.to raise_error(/#{field}.*missing/i) }
      end
    end

    context "optional domain_name" do
      before { project_deployment["domain_name"] = "example.com" }
      it { expect { subject }.to_not raise_error }
    end

    context "director_uuid" do
      context "invalid" do
        before { project_deployment["director_uuid"] = "invalid_uuid" }
        it { expect { subject }.to raise_error(/director_uuid.*doesn't validate/) }
      end

      context "current" do
        before { project_deployment["director_uuid"] = "current" }
        it { expect { subject }.to_not raise_error }
      end
    end
  end
end
