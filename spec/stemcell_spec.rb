describe Bosh::Workspace::Stemcell do
  subject { Bosh::Workspace::Stemcell.new(stemcell) }
  let(:stemcell) { { "name" => name, "version" => version } }

  context "given a normal stemcell" do
    let(:name) { "bosh-warden-boshlite-ubuntu-trusty-go_agent" }
    let(:version) { 3 }

    describe "#name_version" do
      its(:name_version) { is_expected.to eq "#{name}/#{version}" }
    end

    describe "attr readers" do
      %w(name version).each do |attr|
        its(attr.to_sym) { is_expected.to eq eval(attr) }
      end
    end
  end
end
