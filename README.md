# Bosh workspace
[![Build Status](https://img.shields.io/travis/cloudfoundry-incubator/bosh-workspace/master.svg?style=flat-square)](https://travis-ci.org/cloudfoundry-incubator/bosh-workspace) [![Test Coverage](https://img.shields.io/codeclimate/coverage/github/rkoster/bosh-workspace.svg?style=flat-square)](https://codeclimate.com/github/rkoster/bosh-workspace) [![Code Climate](https://img.shields.io/codeclimate/github/rkoster/bosh-workspace.svg?style=flat-square)](https://codeclimate.com/github/rkoster/bosh-workspace) [![Dependency Status](https://img.shields.io/gemnasium/cloudfoundry-incubator/bosh-workspace.svg?style=flat-square)](https://gemnasium.com/cloudfoundry-incubator/bosh-workspace) [![Stories in Ready](https://img.shields.io/badge/tracker-waffle.io-blue.svg?style=flat-square)](https://waffle.io/cloudfoundry-incubator/bosh-workspace)

## Depreciation Notice

BOSH workspace is intimately related to how deployment manifests were handled
with [BOSH](bosh-io) v1. At the time, most projects were providing Bash-based
ad-hoc toolchains for building large YAML deployment manifests out of somewhat
smaller YAML pieces called [Spiff](spiff-repo) *templates* and *stubs*.

In this landscape, BOSH Workspace introduced an effort for providing a
standard toolchain around Spiff, giving a chance for better organizing Spiff
templates and stubs into what could be called “infrastructure-as-code“ git
repositories, that could precisely describe staging and production
environments managed by BOSH.

Later, the development of BOSH Workspace has been abandonned in favor of other
tools like [Genesis](genesis-repo) v1, then v2. And on the BOSH side, the v2
CLI has deprecated Spiff and thus the way BOSH Workspace works. Plus,
reference deployment manifests are progressively being distributed as
*deployment* git repos containing a base BOSH v2 deployment along with
*operation files* that implement variants around the base deployment. So,
fewer and fewer projects are shipping Spiff templates anymore.

So, newer ways of organizing BOSH deployment manifests have emerged like
[Genesis](genesis-repo) that has pivoted to Genesis v2 to support BOSH v2 or
[Gstack BOSH Environment](gbe-repo) (or GBE for intimates) that is natively
built around the BOSH v2 CLI.

[bosh-io](https://bosh.io)
[spiff-repo][https://github.com/cloudfoundry-incubator/spiff]
[genesis-repo](https://github.com/starkandwayne/genesis)
[gbe-repo](https://github.com/gstackio/gstack-bosh-environment)


## Introduction

BOSH Workspace is in essence a `bosh` v1 CLI plugin for managing an organized
layout of Spiff stubs and templates that are the basis of typical BOSH v1
deployments. Such organized layout helps in managing consistently the various
infrastructure-as-code environments you might have, like “sandbox”, “pre-prod”
or ”production”, all made of BOSH deployments that are similar but not exactly
the same.

BOSH Workspace aslo noticeably introduces new handly verbs in the `bosh` v1
CLI that make it easier to deploy things. Indeed, running
`bosh prepare deployment` automates the uploading of BOSH Releases and BOSH
Stemcells (the required bits for a BOSH deployment) to the BOSH server.

For a good introduciton on the initial goals of the project (back in 2015),
see the [Introducing bosh-workspace: how we deploy all things BOSH](bws-intro)
video.

[bws-intro](https://youtu.be/MyW2x35mTF8)

## Getting started

Before you start make sure `ruby`, `bundler` and `spiff` are available on your
system. Instructions for installing spiff can found
[here](https://github.com/cloudfoundry-incubator/spiff#installation).


### Creating a workspace repository
First you will have to create a new repo for our company called Foo Group (short FG).
```
git init fg-boshworkspace
cd fg-boshworkspace
```

Lets create the initial files & directories.
```
mkdir deployments templates
echo -e 'source "https://rubygems.org"\n\ngem "bosh-workspace"' > Gemfile
echo "2.1.0" > .ruby-version
echo -e '.stemcells*\n.deployments*\n.releases*\n.stubs*\n' > .gitignore
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
  - cf/cf-resource-pools.yml
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


### Managing sandbox and production environments

The suggested way of doing this is to create many similar deployments in the
`deployments/` folder. They typically have tha same radix like `cf` or `mysql`
as prefix of their name, and be distinguished by a `-sandbox.yml` suffix or
`-prod.yml` depending on your environments names.

Then each of those similar deployment can express variants by including
environment-specific Spiff stubs, or specifying specific configuration in the
`meta` root YAML node. Easy as that. Examples of deployment variants can be
found in [cf-boshworkspace](https://github.com/cloudfoundry-community/cf-boshworkspace/tree/master/deployments).


### Using private boshreleases
When using a boshrelease from a location which requires authentication
a `.credentials.yml` file is required, located at the root of your boshworkspace.
Two types of authentication are supported: `username/password` and `sshkey`.

Example `.credentials.yml` file:
```yaml
- url: https://github.com/example/top-secret-boshrelease.git
  username: foo
  password: bar
- url: ssh://git@github.com/example/super-secret-boshrelease.git
  private_key: |
    -----BEGIN RSA PRIVATE KEY-----
    MIICXAIBAAKBgQDHFr+KICms+tuT1OXJwhCUmR2dKVy7psa8xzElSyzqx7oJyfJ1
    JZyOzToj9T5SfTIq396agbHJWVfYphNahvZ/7uMXqHxf+ZH9BL1gk9Y6kCnbM5R6
    0gfwjyW1/dQPjOzn9N394zd2FJoFHwdq9Qs0wBugspULZVNRxq7veq/fzwIDAQAB
    AoGBAJ8dRTQFhIllbHx4GLbpTQsWXJ6w4hZvskJKCLM/o8R4n+0W45pQ1xEiYKdA
    Z/DRcnjltylRImBD8XuLL8iYOQSZXNMb1h3g5/UGbUXLmCgQLOUUlnYt34QOQm+0
    KvUqfMSFBbKMsYBAoQmNdTHBaz3dZa8ON9hh/f5TT8u0OWNRAkEA5opzsIXv+52J
    duc1VGyX3SwlxiE2dStW8wZqGiuLH142n6MKnkLU4ctNLiclw6BZePXFZYIK+AkE
    xQ+k16je5QJBAN0TIKMPWIbbHVr5rkdUqOyezlFFWYOwnMmw/BKa1d3zp54VP/P8
    +5aQ2d4sMoKEOfdWH7UqMe3FszfYFvSu5KMCQFMYeFaaEEP7Jn8rGzfQ5HQd44ek
    lQJqmq6CE2BXbY/i34FuvPcKU70HEEygY6Y9d8J3o6zQ0K9SYNu+pcXt4lkCQA3h
    jJQQe5uEGJTExqed7jllQ0khFJzLMx0K6tj0NeeIzAaGCQz13oo2sCdeGRHO4aDh
    HH6Qlq/6UOV5wP8+GAcCQFgRCcB+hrje8hfEEefHcFpyKH+5g1Eu1k0mLrxK2zd+
    4SlotYRHgPCEubokb2S1zfZDWIXW3HmggnGgM949TlY=
    -----END RSA PRIVATE KEY-----
```

## Install Notes

### OSX
cmake isneeded and libssh2 is optionally (only needed when using cloning over ssh)
```
brew install cmake libssh2 pkg-config
```

### Ubuntu
cmake and libcurl4-openssl-dev is needed for rugged install

```
sudo apt-get install cmake libcurl4-openssl-dev libssh2-1-dev
```

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

## List of Contributors

* [Swisscom](https://www.swisscom.ch)
* [Stark & Wayne](http://starkandwayne.com)
