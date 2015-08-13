require 'io/wait'
require 'webrick'
require 'webrick/httpproxy'
require 'vcr'

VCR.configure do |config|
  config.hook_into :webmock
  config.cassette_library_dir = asset_dir('cassettes')
  config.debug_logger = File.open('/tmp/vcr.log', 'w')
  config.default_cassette_options = { :record => :new_episodes }
end

module WEBrick
  class VCRProxyServer < HTTPProxyServer
    def service(*args)
      VCR.use_cassette('proxied') { super(*args) }
    end
  end
end

describe "git clone with transparent proxy" do
  PROXY = 'http://127.0.0.1:9000'

  before do
    reader, writer = IO.pipe

    @pid = fork do
      reader.close

      RSpec.world.wants_to_quit = true # don't show rspec quit message in fork
      at_exit { exit! } # don't rerun all specs on exit of fork

      log_file = File.open '/tmp/vcr_proxy.log', 'a+'
      log = WEBrick::Log.new log_file

      $stderr = writer

      server = WEBrick::VCRProxyServer.new(ProxyURI: PROXY)

      trap('INT') { server.shutdown }
      server.start
    end

    raise 'VCR Proxy did not start in 10 seconds' unless reader.wait(10)
#    sleep(2)
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
        repo_url = 'http://localhost/foo/bar.git'
        repo_url = 'http://localhost:8000/TestGitRepository/.git/'

        puts `export https_proxy=#{PROXY} && curl repo_url + "info/refs?service=git-upload-pack" -vv`

#        Rugged::Repository.clone_at(repo_url, dir)
#        expect(IO.read(File.join(dir, 'master.txt'))).to match /On master/
      end
    end
  end
end
