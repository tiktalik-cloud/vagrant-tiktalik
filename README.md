# Vagrant Tiktalik.com Provider

This is a [Vagrant](http://www.vagrantup.com) 1.2+ plugin that adds an [Tiktalik.com](https://tiktalik.com)
provider to Vagrant, allowing Vagrant to control and provision machines in Tiktalik cloud.

**NOTE:** This plugin requires Vagrant 1.2+,

## Features

* Boot Tiktalik instances.
* SSH into the instances.
* Provision the instances with any built-in Vagrant provisioner, ie. ansible
* Minimal synced folder support via `rsync`.

## Usage

Install using standard Vagrant 1.1+ plugin installation methods.

```
$ vagrant plugin install vagrant-tiktalik

Installing the 'vagrant-tiktalik' plugin. This can take a few minutes...
Installed the plugin 'vagrant-tiktalik (0.0.1)'!
```

After installing, run `vagrant up` and specify the `tiktalik` provider.

```
$ vagrant up --provider=tiktalik

Bringing machine 'default' up with 'tiktalik' provider...
[default] Launching an instance with the following settings...
[default]  -- Image: 4a2b3e72-47f1-4e88-b482-1834478ade28
[default]  -- Hostname: vagrant-default
[default]  -- Size: 0.5
[default]  -- SSH key: d5c6b671-6cba-41fe-9020-5d5e1dda85f9
[default]  -- Networks: ["212c7fd1-6018-41ff-9a01-a37956517237"]
[default] Waiting for instance to become "ready"...
[default] Waiting for SSH to become available...
[default] Machine is booted and ready for use!
[default] Rsyncing folder: /root/f/ => /vagrant
```

Of course prior to doing this, you'll need to obtain an Tiktalik-compatible
box file for Vagrant.

## Quick Start

After installing the plugin (instructions above), the quickest way to get
started is to actually use a dummy Tiktalik box and specify all the details
manually within a `config.vm.provider` block. So first, add the dummy
box using any name you want:

```
$ vagrant box add dummy https://github.com/tiktalik-cloud/vagrant-tiktalik/raw/master/box/tiktalik.box

Downloading or copying the box...
Extracting box...e: 0/s, Estimated time remaining: --:--:--)
Successfully added box 'dummy' with provider 'tiktalik'!
```

And then make a Vagrantfile that looks like the following, filling in
your information where necessary.

```ruby
Vagrant.configure('2') do |config|
  config.vm.provider :tiktalik do |provider, override|
    # path to private ssh key, public one has to me uploaded to
    # tiktalik.com and it's UUID provided below as `provider.ssh_key`
    # please note that DSA key will work just fine
    override.ssh.private_key_path = '~/.ssh/id_rsa'

    override.vm.box = 'tiktalik'

    # hostname for your instance, ie vagrant-host.youraccount.p2.tiktalik.com
    # override.vm.hostname = 'vagrant-host'

    # api credentials, get them from https://tiktalik.com/panel/#apikeys
    provider.api_key = 'api key'
    provider.api_secret = 'api secret'

    # system image UUID, this one is for Ubuntu 12.04.3 LTS 64-bit
    # get more ids from https://tiktalik.com/panel/#templates
    provider.image = '4a2b3e72-47f1-4e88-b482-1834478ade28'

    # your SSH key UUID, get one from https://tiktalik.com/panel/#sshkeys
    provider.ssh_key = 'here goes ssh key uuid'
  end
end
```

And then run `vagrant up --provider=tiktalik`.

This will start an Ubuntu 12.04 instance within your account.
And assuming your SSH information was filled in properly
within your Vagrantfile, SSH and provisioning will work as well.

Note that normally a lot of this boilerplate is encoded within the box
file, but the box file used for the quick start, the "dummy" box, has
no preconfigured defaults.

If you have issues with SSH connecting, make sure that the instances
are being launched with a security group that allows SSH access.

## Configuration

This provider exposes quite a few provider-specific configuration options:

* `image` - System image UUID, full list available at:
  https://tiktalik.com/panel/#templates
* `size` - Instance size, ie. 0.25, 0.5, 1, ...
  Check out our pricing list for other sizes:
  https://tiktalik.com/pricing#unit/2
* `ssh_key` - SSH key UUID.  Key has to be uploaded beforehand.
  Admin panel URL is https://tiktalik.com/panel/#sshkeys
* `api_key` - API key and ...
* `api_secret` - ... secret are required API creditentials.
  Go to admin panel to get them: https://tiktalik.com/panel/#apikeys

## Networks

Networking features in the form of `config.vm.network` are not
supported with `vagrant-tiktalik`, currently. If any of these are
specified, Vagrant will emit a warning, but will otherwise boot
the Tiktalik instance.

## Synced Folders

There is minimal support for synced folders. Upon `vagrant up`,
`vagrant reload`, and `vagrant provision`, the Tiktalik provider will use
`rsync` (if available) to uni-directionally sync the folder to
the remote machine over SSH.

This is good enough for all built-in Vagrant provisioners (shell,
chef, and puppet) to work!

## Development

To work on the `vagrant-tiktalik` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

```
$ bundle
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
and add the following line to your `Vagrantfile` 
```ruby
Vagrant.require_plugin "vagrant-tiktalik"
```
Use bundler to execute Vagrant:
```
$ bundle exec vagrant up --provider=tiktalik
```

## Thanks

Our plugin is based on excellent Vagrant AWS Provider plugin.
