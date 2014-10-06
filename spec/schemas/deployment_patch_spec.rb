module Bosh::Workspace::Schemas
  describe DeploymentPatch do
    before do
      allow_any_instance_of(Releases).to receive(:validate).with(:releases)
      allow_any_instance_of(Stemcells).to receive(:validate).with(:stemcells)
    end

    let(:deployment_patch) do
      {
        "stemcells" => :stemcells,
        "releases" => :releases,
        "templates_ref" => "477d1228a9f27815d6df3ab977235ab26eecbba6"
      }
    end

    subject { DeploymentPatch.new.validate(deployment_patch) }

    %w(stemcells releases).each do |field|
      context "missing #{field}" do
        before { deployment_patch.delete field }
        it { expect { subject }.to raise_error(/#{field}.*missing/i) }
      end
    end

    context "optional templates_ref" do
      before { deployment_patch.delete "templates_ref" }
      it { expect { subject }.to_not raise_error }
    end
  end
end
