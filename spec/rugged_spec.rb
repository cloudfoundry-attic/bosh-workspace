# Excluded by default can be executed by running:
# rspec spec/rugged_spec.rb --tag rugged

describe "Rugged::Credentials allowed_types", rugged: true do
  let(:repo) { Rugged::Repository.new(project_root)}
  let(:remote) { repo.remotes.create_anonymous(url) }
  let(:auth_callback) { double }

  subject { remote.ls(credentials: auth_callback).first }

  context 'git protocol' do
    let(:url) { "git://github.com/example/foo.git" }
    it "does not support authentication" do
      allow(auth_callback).to receive(:call)
      expect{ subject }.to raise_error /repository not found/i
    end
  end

  context "with allowed_types" do
    let(:user) { nil }
    before do
      expect(auth_callback).to receive(:call).with(url, user, allowed_types)
        .and_return(Rugged::Credentials::Default.new)
    end

    context 'https protocol' do
      let(:url) { "https://github.com/example/foo.git" }
      let(:allowed_types) { [:plaintext] }

      it "allows plaintext" do
        expect{ subject }.to raise_error /invalid credential type/i
      end
    end

    context 'http protocol' do
      let(:url) { "http://github.com/example/foo.git" }
      let(:allowed_types) { [:plaintext] }

      it "allows plaintext" do
        expect{ subject }.to raise_error /invalid credential type/i
      end
    end

    context 'ssh protocol style 1' do
      let(:url) { "git@github.com:example/foo.git" }
      let(:user) { "git" }
      let(:allowed_types) { [:ssh_key] }

      it "allows ssh_key" do
        expect{ subject }.to raise_error /invalid credential type/i
      end
    end

    context 'ssh protocol style 2' do
      let(:url) { "ssh://git@github.com/example/foo.git" }
      let(:user) { "git" }
      let(:allowed_types) { [:ssh_key] }

      it "allows ssh_key" do
        expect{ subject }.to raise_error /invalid credential type/i
      end
    end
  end
end
