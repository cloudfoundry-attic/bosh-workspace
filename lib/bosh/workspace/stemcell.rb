module Bosh::Workspace
  class Stemcell
    attr_reader :name, :version, :file

    def initialize(stemcell, stemcells_dir)
      @name = stemcell["name"]
      @version = stemcell["version"]
      @light = stemcell["light"]
      @file = File.join(stemcells_dir, file_name)
    end

    def name_version
      "#{name}/#{version}"
    end

    def file_name
      prefix = @light ? 'light-' : ''
      name.gsub(/^bosh-/, "#{prefix}bosh-stemcell-#{version}-") + '.tgz'
    end

    def downloaded?
      File.exist? file
    end
  end
end
