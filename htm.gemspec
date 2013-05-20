# -*- encoding: utf-8 -*-
require File.expand_path('../lib/htm/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Romain Franceschini"]
  gem.email         = ["franceschini.romain@gmail.com"]
  gem.description   = %q{HTM}
  gem.summary       = %q{Hierarchical Temporal Memory}
  gem.homepage      = "https://github.com/romain1189/htm"
  gem.license       = 'NUMENTA'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec)/})
  gem.name          = "htm"
  gem.require_paths = ["lib"]
  gem.version       = HTM::VERSION.dup

  gem.add_dependency('celluloid', '~> 0.14.0')
  gem.add_dependency('ffi-rzmq', '~> 1.0.1')

  gem.add_development_dependency('bundler', '~> 1.3')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('minitest')
  gem.add_development_dependency('benchmark_suite')
end
