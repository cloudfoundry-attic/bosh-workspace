# Bosh workspace [![Build Status](https://travis-ci.org/rkoster/bosh-workspace.svg?branch=master)](https://travis-ci.org/rkoster/bosh-workspace) [![Test Coverage](https://codeclimate.com/github/rkoster/bosh-workspace/coverage.png)](https://codeclimate.com/github/rkoster/bosh-workspace) [![Code Climate](https://codeclimate.com/github/rkoster/bosh-workspace.png)](https://codeclimate.com/github/rkoster/bosh-workspace)

This is a `bosh` cli plugin for creating reproducible and upgradable deployments.

## Getting started
Before you start make sure ruby, bundler and spiff are available on your system.
Instructions for installing spiff can found [here](https://github.com/cloudfoundry-incubator/spiff#installation).

### Creating a workspace repository
First you will have to create a new repo for our company called Foo Group (short FG).
```
git init fg-boshworkspace
cd fg-boshworkspace
```

Lets create the initial files & directories.
```
mkdir deployments templates
echo 'source "https://rubygems.org"\n\ngem "bosh-workspace"' > Gemfile
echo "2.0.0" > .ruby-version
echo '.stemcells*\n.deployments*\n.releases*\n.stubs*\n' > .gitignore
```

Now install the gems by running bundler.
```
bundle install
```

Lets finish by making an initial commit.
```
git add .
git commit -m "Initial commit"
```

### Creating a first deployment
For demonstration purposes we will deploy Cloud Foundry on bosh-lite.
The steps below will show the bosh-workspace equivalent of [bosh-lite manual deploy instructions](https://github.com/cloudfoundry/bosh-lite#manual-deploy).

Before we start make sure you have access to properly [installed bosh-lite](https://github.com/cloudfoundry/bosh-lite#install).

We will start by targetting our bosh-lite.
```
bosh target 192.168.50.4
bosh login admin admin
```

Now lets create our deployment file.
```
cat >deployments/cf-warden.yml <<EOL
---
name: cf-warden
director_uuid: current

releases:
  - name: cf
    version: latest
    git: https://github.com/cloudfoundry/cf-release.git

stemcells:
  - name: bosh-warden-boshlite-ubuntu-lucid-go_agent
    version: 60

templates:
  - cf/cf-deployment.yml
  - cf/cf-jobs.yml
  - cf/cf-properties.yml
  - cf/cf-infrastructure-warden.yml
  - cf/cf-minimal-dev.yml

meta:
  default_quota_definitions:
    default:
      memory_limit: 102400 # Increased limit for demonstration purposes
EOL
```

Now lets use this deployment and upload it's dependencies.
```
bosh deployment cf-warden
bosh prepare deployment
```

Lets make sure to above template paths exist.
```
ln -s ../.releases/cf/templates templates/cf
```

To finish we only have to start the deployment process and commit our changes.
```
bosh deploy
git add . && git commit -m "Added cf-warden deployment"
```
Congratulations you should now have a running Cloud Foundry.
For further reference on how to start using it go to the [bosh-lite documentation](https://github.com/cloudfoundry/bosh-lite#try-your-cloud-foundry-deployment).

## Experimental
### dns support
Dns support can be enabled by adding a `domain_name` property to your deployment.
For example: `domain_name: microbosh` or if you are using a normal bosh just use `bosh`.
When enabled, a transformation step will be executed after the spiff merge.
Which will transform all the static ip references into domain names.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
