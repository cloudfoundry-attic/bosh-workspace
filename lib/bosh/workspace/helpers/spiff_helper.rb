module Bosh::Workspace
  module SpiffHelper
    include Bosh::Exec

    def spiff_merge(templates, target_file)
      spiff(:merge, templates) do |output|
        File.open(target_file, 'w') { |file| file.write(output) }
      end
    end

    private

    def spiff(verb, params)
      cmd = ["spiff", verb.to_s] + params + ["2>&1"]
      sh(cmd.join(" "), :yield => :on_false) do |result|
        spiff_not_found if result.not_found?
        spiff_failed(result.command, result.output) if result.failed?
        yield result.output
      end
    end

    def spiff_not_found
      say("Can't find spiff in $PATH".make_red)
      say("Go to spiff.cfapps.io for installation instructions")
      err("Please make sure spiff is installed")
    end

    def spiff_failed(command, output)
      say("Command failed: '#{command}'")
      err(output)
    end
  end
end
