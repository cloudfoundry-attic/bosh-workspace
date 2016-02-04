module Bosh::Workspace
  class Release
    REFSPEC = ['HEAD:refs/remotes/origin/HEAD','*:refs/remotes/origin/*']
    attr_reader :name, :git_url, :repo_dir

    def initialize(release, releases_dir, credentials_callback, options = {})
      @name                 = release["name"]
      @ref                  = release["ref"]
      @path                 = release["path"]
      @spec_version         = release["version"].to_s
      @git_url              = release["git"]
      @repo_dir             = File.join(releases_dir, @name)
      @url                  = release["url"]
      @credentials_callback = credentials_callback
      @offline              = options[:offline]
    end

    def update_repo(options = {})
      fetch_repo
      hash = ref || release[:commit]
      update_repo_with_ref(repo, hash)
      update_submodules
    end

    def manifest_file
      File.join(repo_dir, manifest)
    end

    def manifest
      release[:manifest]
    end

    def name_version
      "#{name}/#{version}"
    end

    def version
      release[:version]
    end

    def ref
      @ref && repo.lookup(@ref).oid
    end

    def release_dir
      @path ? File.join(@repo_dir, @path) : @repo_dir
    end

    def url
      @url && @url.gsub("^VERSION^", version)
    end

    private

    def update_submodules
      required_submodules.each do |submodule|
        fetch_repo(submodule_repo(submodule.path, submodule.url))
        update_repo_with_ref(submodule.repository, submodule.head_oid)
      end
    end

    def required_submodules
      symlink_templates.map { |t| submodule_for(t) }.compact
    end

    def repo_path(path)
      File.join(@repo_dir, path)
    end

    def submodule_repo(path, url)
      dir = repo_path(path)
      repo_exists?(dir) ? open_repo(dir) : init_repo(dir, url)
    end

    def repo
      repo_exists? ? open_repo : init_repo
    end

    def fetch_repo(_repo = repo)
      return if offline?
      _repo.fetch('origin', REFSPEC, credentials: @credentials_callback)
      commit = _repo.references['refs/remotes/origin/HEAD'].resolve.target_id
      update_repo_with_ref(_repo, commit)
    end

    def repo_exists?(dir = @repo_dir)
      File.exist?(File.join(dir, '.git'))
    end

    def open_repo(dir = @repo_dir)
      Rugged::Repository.new(dir)
    end

    def init_repo(dir = @repo_dir, url = @git_url)
      offline_err(url) if offline?
      FileUtils.mkdir_p File.dirname(dir)
      Rugged::Repository.init_at(dir).tap do |repo|
        repo.remotes.create('origin', url)
      end
    end

    def offline_err(url)
      err "Cloning repo: '#{url}' not allowed in offline mode"
    end

    def update_repo_with_ref(repository, ref)
      repository.checkout_tree ref, strategy: :force
      repository.checkout ref, strategy: :force
    end

    def new_style_repo
      base = @path ? File.join(@path, 'releases') : 'releases'
      dir = File.join(repo_dir, base, @name)
      File.directory?(dir) && !File.symlink?(dir)
    end

    def releases_dir
      dir = new_style_repo ? "releases/#{@name}" : "releases"
      @path ? File.join(@path, dir) : dir
    end

    def releases_tree
      repo.lookup(repo.head.target.tree.path(releases_dir)[:oid])
    end

    # transforms releases/foo-1.yml, releases/bar-2.yml to:
    # [ { version: "1", manifest: releases/foo-1.yml } ]
    def final_releases
      @final_releases ||= begin
        final_releases = []
        releases_tree.walk_blobs(:preorder) do |_, entry|
          next if entry[:filemode] == 40960 # Skip symlinks
          next unless version = entry[:name][/#{@name}-(.+)\.yml/, 1]
          final_releases << { version: version, manifest: entry[:name] }
        end
        final_releases.sort! { |a, b| a[:version].to_i <=> b[:version].to_i }
      end
    end

    def repo_blame(path)
      Rugged::Blame.new(repo, path).reduce do |m, h|
        return h unless m
        return h if h[:final_signature][:time] > m[:final_signature][:time]
        return m
      end
    end

    def release
      return @release if @release
      latest_offline_warning if latest? && offline?
      release = final_releases.last if latest?
      release ||= final_releases.find { |v| v[:version] == @spec_version }
      missing_release_err(@spec_version, @name) unless release
      @release = lookup_release_ref(release)
    end

    def lookup_release_ref(release)
      b = repo_blame(File.join(releases_dir, release[:manifest]))
      release.merge(manifest: b[:orig_path], commit: b[:final_commit_id])
    end

    def missing_release_err(version, name)
      err "Could not find version: #{version} for release: #{name}"
    end

    def latest_offline_warning
      warning "Using 'latest' local version since in offline mode"
    end

    def templates_dir
      repo_path 'templates'
    end

    def symlink_target(file)
      return File.readlink(file) if File.readlink(file).start_with?("/")
      File.expand_path(File.join(File.dirname(file), File.readlink(file)))
    end

    def submodule_for(file)
      repo.submodules.find { |s| file.start_with? repo_path(s.path) }
    end

    def symlink_templates
      return [symlink_target(templates_dir)] if File.symlink?(templates_dir)
      return [] unless File.exist?(templates_dir)
      Find.find(templates_dir)
        .select { |f| File.symlink?(f) }.map { |f| symlink_target(f) }
    end

    def offline?
      @offline
    end

    def latest?
      @spec_version == "latest"
    end
  end
end
