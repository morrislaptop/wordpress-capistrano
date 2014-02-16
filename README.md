# Capistrano::Composer

A set of recipes for working with WordPress (via WP CLI) and Capistrano 3.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'capistrano', '~> 3.0.0'
gem 'wordpress-capistrano'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install wordpress-capistrano

## Usage

Require the module in your `Capfile`:

```ruby
require 'wordpress/capistrano'
```

`wordpress/capistrano` comes with 4 tasks:

* wordpress:push_db
* wordpress:pull_db
* wordpress:deploy_db
* wordpress:sync_content

The `wordpress:deploy_db` and `wordpress:sync_content` tasks will run before deploy:updated as part of
Capistrano's default deploy, or can be run in isolation with:

```bash
$ cap production wordpress:deploy_db
$ cap production wordpress:sync_content
```

### Other Recommended Settings

This gem does not have libraries to perform common tasks like symlinking wp-content/uploads or symlinking database
configuration files. Some recommended settings to go along with your deploy.rb are below.

```ruby
set :url, 'http://www.wordpress.org'
set :local_url, 'lid0043.localhost'
set :wp_path, '.'
```

### Configuration

Configurable options, shown here with defaults:

```ruby
set :url, 'http://www.wordpress.org'
set :local_url, 'lid0043.localhost'
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Also, please ask the owner of the capistrano-wordpress gem to give up his name!

## Credits

* https://github.com/herrkris/wordpress-capistrano
* https://github.com/capistrano/composer