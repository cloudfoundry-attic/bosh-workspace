require 'bosh/workspace/rspec'

describe "rspec shared bosh-workspace example" do
  deployment = {
    'director_uuid' => 'e4802655-2dfe-459f-8344-1e3ea56b3feb',
    'name' => 'foo',
    'releases' => [],
    'stemcells' => [],
    'templates' => [
      'deployment.yml'
    ],
    'meta' => {
      'foo' => 'bar'
    }
  }
  deployment_template = {
    'director_uuid' => '(( merge ))',
    'name' => '(( merge ))',
    'releases' => '(( merge ))',
    'jobs' => []
  }

  deployment_file = get_tmp_yml_file_path(deployment).tap do |d|
    templates_path = File.expand_path('../../templates', d)
    FileUtils.mkdir_p templates_path
    IO.write(
      File.join(templates_path, 'deployment.yml'),
      deployment_template.to_yaml
    )
  end

  context "given a stub file" do
    stub = { 'name' => 'bar' }

    result = {
      'director_uuid' => '00000000-0000-0000-0000-000000000000',
      'name' => 'bar',
      'releases' => [],
      'jobs' => []
    }

    include_examples(
      "behaves as bosh-workspace deployment",
      deployment_file,
      get_tmp_yml_file_path(result),
      get_tmp_yml_file_path(stub)
    )
  end

  context "when stub file is absent" do
    non_existent_stub = File.join(Dir.mktmpdir, 'foobar')

    result = {
      'director_uuid' => 'e4802655-2dfe-459f-8344-1e3ea56b3feb',
      'name' => 'foo',
      'releases' => [],
      'jobs' => []
    }

    include_examples(
      "behaves as bosh-workspace deployment",
      deployment_file,
      get_tmp_yml_file_path(result),
      non_existent_stub
    )
  end
end
