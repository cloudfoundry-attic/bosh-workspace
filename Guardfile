guard :rspec, cmd: 'rspec' do
  notification :off
  watch(%r{^spec/(.+_spec)\.rb$})
  watch(%r{^lib/bosh/cli/commands/(.+)\.rb$})    { |m| "spec/commands/#{m[1]}_spec.rb" }
  watch(%r{^lib/bosh/workspace/(.+)\.rb$})    { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^lib/bosh/workspace/(.+)\.rake$})    { |m| "spec/#{m[1]}_task_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end
