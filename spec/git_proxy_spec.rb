describe "git clone with transparent proxy" do
  it 'clones through proxies' do
    Dir.mktmpdir do |dir|
      proxy_url = "http://127.0.0.1:#{proxy.port}"
#       proxy_url = "http://127.0.0.1:8888"
#      proxy_url = "http://127.0.0.1:52973"

      env = {
        HTTP_PROXY: proxy_url,
        HTTPS_PROXY: proxy_url,
        http_proxy: proxy_url,
        https_proxy: proxy_url
      }

      with_modified_env env do
        #        repo_url = 'http://localhost/foo/bar.git'
        #        repo_url = 'http://localhost:8000/TestGitRepository/.git/'
        repo_url = 'http://github.com/libgit2/TestGitRepository.git'

#        puts `export https_proxy=#{proxy_url} && curl -k #{repo_url}/info/refs?service=git-upload-pack -vv`

#         `export https_proxy=#{proxy_url} && \
#               curl -k -X POST  #{repo_url}/git-upload-pack -vv \
#               -H 'Accept:application/x-git-upload-pack-result' \
#               -H 'Content-Type:application/x-git-upload-pack-request' -d \
# '0074want 0966a434eb1a025db6b71485ab63a3bfbea520b6 multi_ack_detailed side-band-64k include-tag thin-pack ofs-delta \n0032want 49322bb17d3acc9146f98c97d078513228bbf3c0
# 0032want 42e4e7c5e507e113ebbb7801b16b52cf867b7ce1
# 0032want d96c4e80345534eccee5ac7b07fc7603b56124cb
# 0032want 55a1a760df4b86a02094a904dfa511deb5655905
# 0032want 8f50ba15d49353813cc6e20298002c0d17b0a9ee
# 0032want 6e0c7bdb9b4ed93212491ee778ca1c65047cab4e
# 00000009done
# '`
#        sleep 20
        Rugged::Repository.clone_at(repo_url, dir)
        expect(IO.read(File.join(dir, 'master.txt'))).to match /On master/
      end
    end
  end
end
