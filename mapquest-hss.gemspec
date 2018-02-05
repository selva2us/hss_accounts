# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "hss/accounts/version"

Gem::Specification.new do |gem|
  gem.name = "hss_accounts"
  gem.version = Hss::Accounts::VERSION
  gem.platform = Gem::Platform::RUBY

  gem.authors = ["Mike Ringrose", "Devin Brown", "Justin Beal"]
  gem.email    = ["mikeringrose@gmail.com", "devin.brown@mapquest.com", "justin.beal@mapquest.com"]
  gem.description = %q{This is the HSS gem which is specifc to mq-accounts.}
  gem.summary    = %q{This gem deals with the HSS image resizing for mq-accounts.}
  gem.homepage  = "https://stash.ops.aol.com/projects/MAPQUEST/repos/hss_accounts/browse"

  gem.require_paths = ["lib"]
  gem.files = `git ls-files`.split($\)
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
end
