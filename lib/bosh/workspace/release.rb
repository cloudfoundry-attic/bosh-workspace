require "git"
module Bosh::Workspace
  class Release
    def initialize(release, releases_dir)
      @name = release["name"]
      @version = release["version"]
      @git_uri = release["git"]
      @work_dir = File.join(releases_dir)
    end

    def checkout_current_version
      repo.pull
      repo.checkout(current_version_ref)
    end

    private

    def repo
      if File.directory?(repo_dir)
        @repo ||= Git.open(repo_dir)
      else
        FileUtils.mkdir_p(@work_dir)
        @repo = Git.clone(@git_uri, @name, path: @work_dir)
      end
    end

    def current_version_ref
      repo.log().object("releases/#{available_versions[current_version]}")
    end

    def current_version
      if @version == "latest"
        available_versions.keys.sort.last
      else
        version = @version.to_i
        unless available_versions[version]
          err("Could not find version: #{@version} for release: #{@name}")
        end
        version
      end
    end

    # transforms releases/foo-1.yml, releases/bar-2.yml to:
    # { "1" => foo-1.yml, "2" => bar-2.yml }
    def available_versions
      @available_versions ||= begin
        Hash[Dir[File.join(repo_dir, "releases", "*.yml")].
        reject { |f| f[/index.yml/] }.
        map { |dir| File.basename(dir) }.
        map { |version| [ version[/(\d+)/].to_i, version ] }]
      end
    end

    def repo_dir
      File.join(@work_dir, @name)
    end
  end
end
