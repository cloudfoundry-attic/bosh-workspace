module Bosh::Workspace
  describe GitRemoteUrl do
    describe '.protocol' do
      subject { GitRemoteUrl.new(url) }

      context 'git protocol' do
        let(:url) { "git://example.com/foo" }
        its(:protocol) { is_expected.to eq(:git) }
      end

      context 'https protocol' do
        let(:url) { "https://example.com/foo" }
        its(:protocol) { is_expected.to eq(:https) }
      end

      context 'http protocol' do
        let(:url) { "http://example.com/foo" }
        its(:protocol) { is_expected.to eq(:http) }
      end

      context 'ssh protocol style 1' do
        let(:url) { "foo@example.com:foo" }
        its(:protocol) { is_expected.to eq(:ssh) }
      end

      context 'ssh protocol style 2' do
        let(:url) { "ssh://foo@example.com/foo" }
        its(:protocol) { is_expected.to eq(:ssh) }
      end

      context 'unsupported protocol' do
        let(:url) { "foo://foo@example.com/foo" }
        it 'raises' do
          expect { subject.protocol() }.to raise_error /unsupported protocol/i
        end
      end
    end
  end
end
