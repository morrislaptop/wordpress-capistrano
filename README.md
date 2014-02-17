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

* wordpress:db:push
* wordpress:db:pull
* wordpress:db:deploy
* wordpress:content:sync

You can run any of these by issuing the following commands..

```bash
$ bundle exec cap production wordpress:db:push
$ bundle exec cap production wordpress:db:pull
$ bundle exec cap production wordpress:db:deploy
$ bundle exec cap production wordpress:content:sync
```

None of these tasks are built into the default Capistrano deploy as they are potentially damaging.

To add any of them (I've used wordpress:db:deploy and wordpress:content:sync on sites which I know all content updates are version controlled)

```ruby

```

### Other Recommended Settings

This gem does not have libraries to perform common tasks like symlinking wp-content/uploads or symlinking database
configuration files. Some recommended settings to go along with your deploy.rb are below.

#### Use Composer for WordPress and Plugins

```json
{
	"repositories": [
		{
			"type": "composer",
			"url": "http://wpackagist.org"
		},
		{
			"type": "package",
			"package": {
				"name": "wordpress",
				"type": "webroot",
				"version": "3.8.1",
				"dist": {
					"type": "zip",
					"url": "http://en-au.wordpress.org/wordpress-3.8.1-en_AU.zip"
				},
				"require": {
					"fancyguy/webroot-installer": "1.0.0"
				}
			}
		},
	],
	"require": {
		"php": ">=5.3.0",
		"wordpress": "3.8.1",
		"fancyguy/webroot-installer": "1.0.0",
		"wpackagist/advanced-custom-fields": "*",
		"wpackagist/codepress-admin-columns": "*",
		"wpackagist/custom-post-type-ui": "*",
		"wpackagist/wordpress-importer": "*",
		"wpackagist/duplicate-post": "*",
		"wpackagist/simple-page-ordering": "*",
		"wpackagist/adminimize": "*"
	},
	"require-dev": {
		"wpackagist/debug-bar": "*",
		"wpackagist/pretty-debug": "*"
	},
	"extra": {
		"webroot-dir": "wp",
		"webroot-package": "wordpress"
	}
}
```

#### Use Linked Dirs and Linked Files

```ruby
set :linked_dirs, %w{wp-content/uploads}
set :linked_files, %w{wp-config.local.php}
```


### Configuration

Configurable options, shown here with defaults:

```ruby
set :url, 'www.wordpress.org'
set :local_url, 'localhost'
set :wp_path, '.'
set :wp_uploads, 'wp-content/uploads'
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