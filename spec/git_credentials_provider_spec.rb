module Bosh::Workspace
  describe GitCredentialsProvider do
    let!(:credentials_provider) { GitCredentialsProvider.new(file) }
    let(:file) { "credentials_file" }
    let(:file_exist) { true }
    let(:valid) { true }
    let(:url_protocols) { [] }
    let(:url) { 'http://foo.com/bar.git' }
    let(:user) { nil }
    let(:result) { nil }
    let(:allowed_types) { [:plain_text] }
    let(:credentials) do
      instance_double "Bosh::Workspace::Credentials",
                      :valid? => valid, url_protocols: url_protocols
    end

    subject { credentials_provider.callback.call url, user, allowed_types }

    before do
      allow(Credentials).to receive(:new).and_return(credentials)
      allow(File).to receive(:exist?).and_return(file_exist)
      allow(credentials).to receive(:find_by_url).with(url).and_return(result)
    end

    describe '#callback' do
      context "with sshkey" do
        let(:user) { 'git' }
        let(:result) { { private_key: 'barkey' } }
        let(:allowed_types) { [:ssh_key] }

        it 'returns Rugged sshkey credentials' do
          expect(Rugged::Credentials::SshKey).to receive(:new) do |args|
            expect(args[:username]).to eq user
            expect(IO.read(args[:privatekey])).to eq('barkey')
          end; subject
        end
      end

      context "with username/password" do
        let(:result) { { username: user, password: 'barpw' } }
        let(:allowed_types) { [:plain_text] }

        it 'returns Rugged user password credentials' do
          expect(Rugged::Credentials::UserPassword).to receive(:new) do |args|
            expect(args[:username]).to eq user
            expect(args[:password]).to eq 'barpw'
          end; subject
        end
      end

      context "without credentials file" do
        let(:file_exist) { false }
        it 'raises an error' do
          expect{ subject }.to raise_error /credentials file does not exist/i
        end
      end

      context "with invalid credentials file" do
        let(:valid) { false }
        before { expect(credentials).to receive(:errors) { ['foo error'] } }
        it 'raises an error' do
          expect{ subject }.to raise_error /is not valid/i
        end
      end

      context "without credentials for given url" do
        let(:result) { nil }
        it 'raises an error' do
          expect{ subject }.to raise_error /no credentials found/i
        end
      end

      context "without protocol support" do
        let(:url_protocols) { {"https://foo.com" => :https } }
        before { expect(Rugged).to receive(:features).and_return([]) }
        it 'raises an error' do
          expect{ subject }.to raise_error /requires https support/i
        end
      end
    end
  end
end

describe "Rugged::Credentials allowed_types" do
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
