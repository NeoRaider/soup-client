# -*- encoding: utf-8 -*-
require File.expand_path('../lib/soup-client/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Matthias Schiffer"]
  gem.email         = ["mschiffer@universe-factory.net"]
  gem.description   = %q{soup.io client}
  gem.summary       = %q{soup.io client}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "soup-client"
  gem.require_paths = ["lib"]
  gem.version       = Soup::Client::VERSION

  gem.add_dependency("faraday")
end
