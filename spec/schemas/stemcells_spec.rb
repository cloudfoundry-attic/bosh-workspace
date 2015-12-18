module Bosh::Workspace::Schemas
  describe Stemcells do
    let(:stemcell) do
      { "name" => "foo", "version" => 1, "light" => true }
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

    context "patch version with multiple dots" do
      let(:stemcells) { stemcell["version"] = "1.2.3"; [stemcell] }
      it { expect { subject }.to_not raise_error }
    end

    context "fails for versions with too many dots" do
      let(:stemcells) { stemcell["version"] = "1.2.3.4"; [stemcell] }
      it { expect { subject }.to raise_error(/version.*should match/i) }
    end

    context "patch version float" do
      let(:stemcells) { stemcell["version"] = 2719.1; [stemcell] }
      it { expect { subject }.to_not raise_error }
    end

    context "version string with all digetes without dots" do
      let(:stemcells) { stemcell["version"] = '0000'; [stemcell] }
      it { expect { subject }.to_not raise_error }
    end

    context "invalid version" do
      let(:stemcells) { stemcell["version"] = "foo"; [stemcell] }
      it { expect { subject }.to raise_error(/version.*should match/i) }
    end

    context "without optional light key" do
      let(:stemcells) { [stemcell.delete_if { |k| k == "light" }] }
      it { expect { subject }.to_not raise_error }
    end

    context "light non boolean" do
      let(:stemcells) { stemcell["light"] = "foo"; [stemcell] }
      it { expect { subject }.to raise_error /true or false/ }
    end
  end
end
