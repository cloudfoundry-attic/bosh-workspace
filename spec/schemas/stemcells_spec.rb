module Bosh::Workspace::Schemas
  describe Stemcells do
    let(:stemcell) do
      {"name" => "foo", "version" => 1}
    end

    subject { Stemcells.new.validate(stemcells) }

    %w(name version).each do |field_name|
      context "missing #{field_name}" do
        let(:stemcells) { [stemcell.delete_if { |k| k == field_name }] }
        it { expect { subject }.to raise_error(/#{field_name}.*missing/i) }
      end
    end

    context "latest version" do
      let(:stemcells) { stemcell["version"] = "latest"; [stemcell] }
      it { expect { subject }.to_not raise_error }
    end

    context "patch version string" do
      let(:stemcells) { stemcell["version"] = "2719.1"; [stemcell] }
      it { expect { subject }.to_not raise_error }
    end

    context "patch version float" do
      let(:stemcells) { stemcell["version"] = 2719.1; [stemcell] }
      it { expect { subject }.to_not raise_error }
    end

    context "invalid version" do
      let(:stemcells) { stemcell["version"] = "foo"; [stemcell] }
      it { expect { subject }.to raise_error(/version.*should match/i) }
    end
  end
end

