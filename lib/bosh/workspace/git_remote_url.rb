module Bosh::Workspace
  class GitRemoteUrl
    def initialize(url)
      @url = url
    end

    def protocol()
      case @url
      when /^git:/
        return :git
      when /^https:/
        return :https
      when /^http:/
        return :http
      when /(@.+:|^ssh:)/
        return :ssh
      else
        raise "Unsupported protocol for remote git url: #{@url}"
      end
    end
  end
end
