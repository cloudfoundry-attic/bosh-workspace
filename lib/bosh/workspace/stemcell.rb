module Bosh::Workspace
  class Stemcell
    attr_reader :name, :version

    def initialize(stemcell)
      @name = stemcell["name"]
      @version = stemcell["version"]
    end

    def name_version
      "#{name}/#{version}"
    end
  end
end
