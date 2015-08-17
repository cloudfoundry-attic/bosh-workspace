require 'io/wait'
require 'webrick'
require 'webrick/httpproxy'

class Net::HTTP::Connect < Net::HTTPRequest
  METHOD = 'CONNECT'
  REQUEST_HAS_BODY  = false
  RESPONSE_HAS_BODY = false
end

describe "git clone with transparent proxy" do
  before do
    EphemeralResponse::Configuration.debug_output = $stderr
    EphemeralResponse.activate

  end

  after do
    EphemeralResponse.deactivate
  end

  PROXY = 'https://127.0.0.1:44567'

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
#        repo_url = 'http://localhost:8000/TestGitRepository/.git/'
        repo_url = 'https://github.com/libgit2/TestGitRepository.git'

        puts `export https_proxy=#{PROXY} && curl -k #{repo_url}/info/refs?service=git-upload-pack -vv`
#        Rugged::Repository.clone_at(repo_url, dir, ignore_cert_errors: true)
        expect(IO.read(File.join(dir, 'master.txt'))).to match /On master/
      end
    end
  end
end
