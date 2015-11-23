describe Bosh::Workspace::Stemcell do
  subject { Bosh::Workspace::Stemcell.new(stemcell, stemcells_dir) }
  let(:stemcells_dir) { ".stemcells" }
  let(:stemcell) { { "name" => name, "version" => version, "light" => light } }

  context "given a normal stemcell" do
    let(:light) { nil }
    let(:name) { "bosh-warden-boshlite-ubuntu-trusty-go_agent" }
    let(:file_name) { "bosh-stemcell-3-warden-boshlite-ubuntu-trusty-go_agent.tgz" }
    let(:version) { 3 }

    describe "#name_version" do
      its(:name_version) { is_expected.to eq "#{name}/#{version}" }
    end

    describe "#file_name" do
      its(:file_name) { is_expected.to eq file_name }
    end

    describe "#downloaded?" do
      before do
        expect(File).to receive(:exist?).with(/\/#{file_name}/).and_return(true)
      end
      its(:downloaded?) { is_expected.to eq true }
    end

    describe "attr readers" do
      let(:file) { "#{stemcells_dir}/#{file_name}" }
      %w(name version file).each do |attr|
        its(attr.to_sym) { is_expected.to eq eval(attr) }
      end
    end
  end

  context "given a light stemcell" do
    let(:light) { true }
    let(:name) { "bosh-aws-xen-hvm-ubuntu-trusty-go_agent" }
    let(:file_name) { "light-bosh-stemcell-3143-aws-xen-hvm-ubuntu-trusty-go_agent.tgz" }
    let(:version) { 3143 }

    describe "#name_version" do
      its(:name_version) { is_expected.to eq "#{name}/#{version}" }
    end

    describe "#file_name" do
      its(:file_name) { is_expected.to eq file_name }
    end

    describe "#downloaded?" do
      before do
        expect(File).to receive(:exist?).with(/\/#{file_name}/).and_return(true)
      end
      its(:downloaded?) { is_expected.to eq true }
    end

    describe "attr readers" do
      let(:file) { "#{stemcells_dir}/#{file_name}" }
      %w(name version file).each do |attr|
        its(attr.to_sym) { is_expected.to eq eval(attr) }
      end
    end
  end
end
