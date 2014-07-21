module Bosh::Workspace
  class Stemcell
    attr_reader :name, :version, :file

    def initialize(stemcell, stemcells_dir)
      @name = stemcell["name"]
      @version = stemcell["version"]
      @file = File.join(stemcells_dir, file_name)
    end

    def file_name
      name.gsub(/^bosh-/, "bosh-stemcell-#{version}-") + ".tgz"
    end

    def downloaded?
      File.exists? file
    end
  end
end
