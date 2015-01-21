module Bosh::Workspace
  module GitCredenialsHelper
    REFSPEC = ['HEAD:refs/remotes/origin/HEAD']

    def fetch_or_clone_repo(dir, url)
      repo = File.exist?(dir) ? open_repo(dir) : init_repo(dir, url)

      options = {}
      unless repo.remotes.create_anonymous(url).check_connection(:fetch)
        options = { credentials: require_credetials_for(url) }
      end

      repo.fetch('origin', REFSPEC, options)
      repo.checkout 'refs/remotes/origin/HEAD', strategy: :force
    end

    private

    def init_repo(dir, url)
      FileUtils.mkdir_p File.dirname(dir)
      Rugged::Repository.init_at(dir).tap do |repo|
        repo.remotes.create('origin', url)
      end
    end

    def open_repo(dir)
      Rugged::Repository.new(dir)
    end

    def credentials
      @credentials ||= Credentials.new(credentials_file)
    end

    def credetials_for(url)
      unless File.exist? credentials_file
        say("Authentication is required for: #{url}".make_red)
        err("Credentials file does not exist: #{credentials_file}".make_red)
      end
      unless credentials.valid?
        say("Validation errors:".make_red)
        thing.errors.each { |error| say("- #{error}") }
        err("'#{credentials_file}' is not valid".make_red)
      end
      if creds = credentials.find_by_url(url)
        load_git_credentials(creds)
      else
        say("Credential look up failed in: #{credentials_file}")
        err("No credentials found for: #{url}".make_red)
      end
    end

    def credentials_file
      File.join work_dir, '.credentails.yml'
    end

    def load_git_credentials(credentials)
      case credentials.keys
      when %i(private_key)
        options = { privatekey: temp_key_file(credentials[:private_key]) }
        Rugged::Credentials::SshKey.new(options)
      when %i(username password)
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
  end
end
