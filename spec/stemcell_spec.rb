describe Bosh::Workspace::Stemcell do
  subject { Bosh::Workspace::Stemcell.new(stemcell, stemcells_dir) }
  let(:stemcells_dir) { ".stemcells" }
  let(:stemcell) { { "name" => name, "version" => version } }
  let(:name) { "bosh-warden-boshlite-ubuntu-trusty-go_agent" }
  let(:file_name) { "bosh-stemcell-3-warden-boshlite-ubuntu-trusty-go_agent.tgz" }
  let(:version) { 3 }

  describe "#name_version" do
    its(:name_version) { should eq "#{name}/#{version}" }
  end

  describe "#file_name" do
    its(:file_name) { should eq file_name }
  end

  describe "#downloaded?" do
    before { File.should_receive(:exists?).with(/\/#{file_name}/).and_return(true) }
    its(:downloaded?) { should eq true }
  end

  describe "attr readers" do
    let(:file) { "#{stemcells_dir}/#{file_name}" }
    %w(name version file).each do |attr| 
      its(attr.to_sym) { should eq eval(attr) }
    end
  end
end
