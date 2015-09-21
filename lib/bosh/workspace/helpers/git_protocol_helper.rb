module Bosh::Workspace
  module GitProtocolHelper
    def git_protocol_from_url(url)
      case url
      when /^git:/
        return :git
      when /^https:/
        return :https
      when /^http:/
        return :http
      when /(@.+:|^ssh:)/
        return :ssh
      else
        return nil
      end
    end
  end
end
