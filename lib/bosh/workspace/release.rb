module Bosh::Workspace
  class Release
    attr_reader :name, :git_url, :repo_dir

    def initialize(release, releases_dir)
      @name = release["name"]
      @ref = release["ref"]
      @spec_version = release["version"]
      @git_url = release["git"]
      @repo_dir = File.join(releases_dir, @name)
    end

    def update_repo
      repo.checkout ref || version_ref, strategy: :force
    end

    def manifest_file
      File.join(repo_dir, manifest)
    end

    def manifest
      final_releases[version]
    end

    def name_version
      "#{name}/#{version}"
    end

    def version
      return final_releases.keys.sort.last if @spec_version == "latest"
      unless final_releases[@spec_version.to_i]
        err("Could not find version: #{@spec_version} for release: #{@name}")
      end
      @spec_version.to_i
    end

    def ref
      @ref && repo.lookup(@ref).oid
    end

    private

    def repo
      @repo ||= Rugged::Repository.new(repo_dir)
    end

    def new_style_repo
      dir = File.join(repo_dir, "releases", @name)
      File.directory?(dir) && !File.symlink?(dir)
    end

    # transforms releases/foo-1.yml, releases/bar-2.yml to:
    # { "1" => foo-1.yml, "2" => bar-2.yml }
    def final_releases
      @final_releases ||= begin
        releases_dir = new_style_repo ? "releases/#{@name}" : "releases"

        Hash[Dir[File.join(repo_dir, releases_dir, "*.yml")]
          .reject { |f| f[/index.yml/] }
          .map { |dir| File.join(releases_dir, File.basename(dir)) }
          .map { |version| [version[/(\d+)/].to_i, version] }]
      end
    end

    def version_ref
      # figure out the last commit which changed the release manifest file
      # in other words the commit sha of the final release
      repo.walk(repo.head.target) do |commit|
        return commit.oid if commit.tree.path(manifest)
      end
    end
  end
end
