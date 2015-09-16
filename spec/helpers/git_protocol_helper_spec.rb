module Bosh::Workspace
  describe GitProtocolHelper do
    include GitProtocolHelper
    describe '#git_protocol_from_url' do
      subject { git_protocol_from_url(url) }

      context 'git protocol' do
        let(:url) { "git://example.com/foo" }
        it { is_expected.to eq(:git) }
      end

      context 'https protocol' do
        let(:url) { "https://example.com/foo" }
        it { is_expected.to eq(:https) }
      end

      context 'http protocol' do
        let(:url) { "http://example.com/foo" }
        it { is_expected.to eq(:http) }
      end

      context 'ssh protocol style 1' do
        let(:url) { "foo@example.com:foo" }
        it { is_expected.to eq(:ssh) }
      end

      context 'ssh protocol style 2' do
        let(:url) { "ssh://foo@example.com/foo" }
        it { is_expected.to eq(:ssh) }
      end

      context 'unsupported protocol' do
        let(:url) { "foo://foo@example.com/foo" }
        it { is_expected.to eq(nil) }
      end
    end
  end
end
