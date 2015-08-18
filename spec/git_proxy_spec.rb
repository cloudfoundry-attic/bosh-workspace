require 'io/wait'

describe "git clone with transparent proxy" do
  PROXY_PORT = 9000

  before do
    reader, writer = IO.pipe

    @pid = fork do
      reader.close

      RSpec.world.wants_to_quit = true # don't show rspec quit message in fork
      at_exit { exit! } # don't rerun all specs on exit of fork

      Billy.configure do |c|
        c.logger = Logger.new(writer)
        c.proxied_request_inactivity_timeout = 50
        c.proxied_request_connect_timeout = 50
        c.proxy_port = PROXY_PORT
      end

      trap('INT') { EM.stop_event_loop }

      Billy::Proxy.new.start(false)
    end

    raise 'Puffing Billy did not start in 10 seconds' unless reader.wait(10)
  end

  after do
    Process.kill('INT', @pid)
  end

  xit 'clones through proxies' do
    Dir.mktmpdir do |dir|
      proxy_url = "http://127.0.0.1:#{PROXY_PORT}"

      env = {
        HTTP_PROXY: proxy_url,
        HTTPS_PROXY: proxy_url,
        http_proxy: proxy_url,
        https_proxy: proxy_url
      }

      with_modified_env env do
        repo_url = 'http://github.com/libgit2/TestGitRepository.git'
        Rugged::Repository.clone_at(repo_url, dir, ignore_cert_errors: true)
        expect(IO.read(File.join(dir, 'master.txt'))).to match /On master/
      end
    end
  end
end
