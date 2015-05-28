module Bosh::Workspace
  module GitCredentialsHelper
    REFSPEC = ['HEAD:refs/remotes/origin/HEAD']

    def fetch_or_clone_repo(dir, url)
      repo = File.exist?(File.join(dir, '.git')) ? open_repo(dir) : init_repo(dir, url)
      fetch_and_checkout(repo)
    end

    def fetch_repo(dir)
      fetch_and_checkout(open_repo(dir))
    end

    private

    def fetch_and_checkout(repo)
      url = repo.remotes['origin'].url
      repo.fetch('origin', REFSPEC, connection_options_for(repo, url))
      commit = repo.references['refs/remotes/origin/HEAD'].resolve.target_id
      repo.checkout_tree commit, strategy: :force
      repo.checkout commit, strategy: :force
    end

    def connection_options_for(repo, url)
      return {} if check_connection(repo, url)
      validate_url_protocol_support!(url)

      options = { credentials: require_credentials_for(url) }
      unless check_connection(repo, url, options)
        say "Using credentials from: #{git_credentials_file}"
        err "Invalid credentials for: #{url}"
      end
      options
    end

    def check_connection(repo, url, options = {})
      repo.remotes.create_anonymous(url).check_connection(:fetch, options)
    end

    def init_repo(dir, url)
      FileUtils.mkdir_p File.dirname(dir)
      Rugged::Repository.init_at(dir).tap do |repo|
        repo.remotes.create('origin', url)
      end
    end

    def open_repo(dir)
      Rugged::Repository.new(dir)
    end

    def git_credentials
      @git_credentials ||= Credentials.new(git_credentials_file)
    end

    def require_credentials_for(url)
      unless File.exist? git_credentials_file
        say("Authentication is required for: #{url}".make_red)
        err("Credentials file does not exist: #{git_credentials_file}".make_red)
      end
      unless git_credentials.valid?
        say("Validation errors:".make_red)
        git_credentials.errors.each { |error| say("- #{error}") }
        err("'#{git_credentials_file}' is not valid".make_red)
      end
      if creds = git_credentials.find_by_url(url)
        load_git_credentials(creds)
      else
        say("Credential look up failed in: #{git_credentials_file}")
        err("No credentials found for: #{url}".make_red)
      end
    end

    def validate_url_protocol_support!(url)
      protocol = GitRemoteUrl.new(url).protocol
      case protocol
      when :git
        err("Somthing is wrong, the git protocol does not support authentication")
      when :https, :ssh
        unless Rugged.features.include? protocol
          say("Please reinstall Rugged gem with #{protocol} support: http://git.io/veiyJ")
          err("Rugged requires #{protocol} support for: #{url}")
        end
      end
    end

    def git_credentials_file
      File.join work_dir, '.credentials.yml'
    end

    def load_git_credentials(git_credentials)
      case git_credentials.keys
      when %i(private_key)
        options = {
          username: 'git',
          privatekey: temp_key_file(git_credentials[:private_key])
        }
        Rugged::Credentials::SshKey.new(options)
      when %i(username password)
        Rugged::Credentials::UserPassword.new(git_credentials)
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
