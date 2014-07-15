module Bosh::Workspace
  class ReleaseManager
    def initialize(releases, work_dir)
      releases_dir = File.join(work_dir, ".releases")
      @releases = releases.map { |r| Release.new(r, releases_dir) }
    end

    def update_release_repos
      @releases.each do |release|
        release.checkout_current_version
      end
    end
  end
end
