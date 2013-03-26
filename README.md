# Super-simple deployment!

Do you have Rails app and a clean server? Now you can easily deploy your app and setup continuous deployment
in 2 commands.

## What it does?

It takes a clean server, sshes into it via `root` and creates an user `rails`, installs RVM, nginx/Passenger,
configures mina for deployment, deploys a simple application that exposes a WebHook that updates the application.

## Assumptions (for now)

* You have a clean Ubuntu 12.10 Server (no installations of nginx, rvm or anything, just clean server)
* You have root password to that server
* You are ok to use RVM, nginx/Passenger (no Apache yet), mina (no Capistrano yet) to Production
* You need a Postgres database on Production
* You need a `rails` user to work with your apps
* You host your code with some Git hosting (BitBucket offers free private repositories)

## Status

Ver much *alpha*

## Installation

Get a clean Ubuntu 12.10 server (other Linuxes and versions are not yet tested).

    $ gem install pointer
    $ pointer init

Edit the file `config/pointer.rb`

    $ pointer deploy:prepare

After that:

    $ pointer

You'll see a list of basic commands


## Known warnings !

WebHook is currently at a known location, calling it with POST exposes a lot of information (it outputs the mina
output). I'm not sure yet that is a security breach somehow, but be advised. I'll update it later. (That will probably get fixed)

User `rails` currently has a no password sudo. (That will probably get fixed)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
