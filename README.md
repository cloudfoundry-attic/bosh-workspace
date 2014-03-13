# Bosh workspace

## Design Goals
Enabling BOSH operators to share common configuration between different deployments.
For example having a `QA` and `production` deployment for which only networking differs.

## Installation
Before you start make sure ruby, bundler and spiff are available on your system.
Instructions for installing spiff can found [here](https://github.com/cloudfoundry-incubator/spiff#installation).

Add this line to your application's Gemfile:

    gem 'bosh-workspace'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bosh-workspace


## Usage
This BOSH plugin improves the deployments work-flow,
by extending some of the build in commands bosh commands.

**Set deployment**
Sets the current deployment. Will search in `./deployments`.
```
bosh deployment cf-warden
```

**Prepare deployment**
Resolves upstream templates (via releases).
Resolves and uploads releases/stemcells.
```
bosh prepare deployment
```

**Deploy**
Merges the specified templates into one deployment manifests using spiff.
And uses this file to initiate a `deploy`.
```
bosh deploy
```

### Deployment file structure
A deployment file has the following structure:

**name:**
The name of your deployment

**director_uuid:**
The director_uuid of the targeted BOSH director

**releases:**
Array of releases used for resolving upstream templates

**meta:**
The meta hash is the last file merged into the final deployment file.
It can be used to define properties deployment specific properties.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
