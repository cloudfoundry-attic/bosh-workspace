module Bosh::Workspace
  class GitCredentialsProvider
    attr_reader :credentials_file

    def initialize(credentials_file)
      @credentials_file = credentials_file
    end

    def callback
      proc do |url, user, allowed_types|
        require_credentials_file_for!(url)
        validate_credentials!
        validate_url_protocol_support!
        credentials_for(url, user, allowed_types)
      end
    end

    private

    def credentials
      @credentials ||= Credentials.new(@credentials_file)
    end

    def require_credentials_file_for!(url)
      return if File.exist? @credentials_file
      say("Authentication is required for: #{url}".make_red)
      err("Credentials file does not exist: #{@credentials_file}".make_red)
    end

    def validate_credentials!
      return if credentials.valid?
      say("Validation errors:".make_red)
      credentials.errors.each { |error| say("- #{error}") }
      err("'#{credentials_file}' is not valid".make_red)
    end

    def validate_url_protocol_support!
      credentials.url_protocols.each do |url, protocol|
        next if Rugged.features.include? protocol
        say("Please reinstall Rugged gem with #{protocol} support: http://git.io/veiyJ")
        err("Rugged requires #{protocol} support for: #{url}")
      end
    end

    def credentials_for(url, user, allowed_types)
      if creds = credentials.find_by_url(url)
        load_git_credentials(creds, user, allowed_types)
      else
        say("Credential look up failed in: #{credentials_file}")
        err("No credentials found for: #{url}".make_red)
      end
    end

    def load_git_credentials(credentials, user, allowed_types)
      case allowed_types
      when %i(ssh_key)
        key_file = temp_key_file(credentials[:private_key])
        Rugged::Credentials::SshKey.new username: user, privatekey: key_file
      when %i(plaintext)
        Rugged::Credentials::UserPassword.new(credentials)
      end
    end

    def temp_key_file(key)
      file = Tempfile.new('sshkey')
      file.write key
      file.close
      File.chmod(0600, file.path)
      file.path
    end

    def say(*args)
      super
    end

    def err(*args)
      super
    end
  end
end
