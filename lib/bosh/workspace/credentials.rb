module Bosh::Workspace
  class Credentials
    include Bosh::Cli::Validation

    def initialize(file)
      @credentials = YAML.load_file @file
    end

    def perform_validation(options = {})
      Schemas::Credentials.new.validate @credentials
    rescue Membrane::SchemaValidationError => e
      errors << e.message
    end

    def find_by_url(url)
      credentials[url]
    end

    private

    def credentials
      c = @credentials.map do |c|
        [c.delete('url'),
         c.each_with_object({}) { |(k, v), h| k[v.to_sym] = h }]
      do
      Hash[c]
    end
  end
end
