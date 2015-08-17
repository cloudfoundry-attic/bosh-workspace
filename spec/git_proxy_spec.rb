require 'io/wait'
require 'webrick'
require 'webrick/httpproxy'

module WEBrick
  class VCRProxyServer < HTTPProxyServer
    def initialize(*args)
      EphemeralResponse.activate
      super(*args)
    end
  end
end

describe "git clone with transparent proxy" do
  PROXY = 'http://127.0.0.1:9000'

  before do
    reader, writer = IO.pipe

    @pid = fork do
      RSpec.world.wants_to_quit = true # don't show rspec quit message in fork
      at_exit { exit! } # don't rerun all specs on exit of fork

      reader.close
      $stderr = writer

      server = WEBrick::VCRProxyServer.new(ProxyURI: PROXY)

      trap('INT') { server.shutdown }
      server.start
    end

    raise 'VCR Proxy did not start in 10 seconds' unless reader.wait(10)
  end

  after do
    Process.kill('INT', @pid)
  end

  it 'clones through proxies' do
    Dir.mktmpdir do |dir|
      env = {
        HTTP_PROXY: PROXY,
        HTTPS_PROXY: PROXY,
        http_proxy: PROXY,
        https_proxy: PROXY
      }

      with_modified_env env do
#        repo_url = 'http://localhost/foo/bar.git'
        repo_url = 'http://localhost:8000/TestGitRepository/.git/'

        puts `export http_proxy=#{PROXY} && curl #{repo_url}/info/refs?service=git-upload-pack -vv`

#        Rugged::Repository.clone_at(repo_url, dir)
#        expect(IO.read(File.join(dir, 'master.txt'))).to match /On master/
      end
    end
  end
end
