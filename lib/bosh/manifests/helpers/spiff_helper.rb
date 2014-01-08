module Bosh::Manifests
  module SpiffHelper
    def spiff
      Bosh::Manifests::SpiffCommand.new
    end
  end

  class SpiffCommand
    include Bosh::Exec

    def merge(templates, target_file)
      run(:merge, templates) do |output|
        File.open(target_file, 'w') { |file| file.write(output) }
      end
    end

    private

    def run(verb, params)
      cmd = ["spiff", verb.to_s] + params + ["2>&1"]
      sh(cmd.join(" "), :yield => :on_false) do |result|
        spiff_not_found if result.failed?
        yield result.output
      end
    end

    def spiff_not_found
      say("Can't find spiff in $PATH".make_red)
      say("Go to spiff.cfapps.io for installation instructions")
      err("Please make sure spiff is installed")
    end
  end
end
