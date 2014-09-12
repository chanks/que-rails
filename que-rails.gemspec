# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'que/rails/version'

Gem::Specification.new do |spec|
  spec.name          = 'que-rails'
  spec.version       = Que::Rails::VERSION
  spec.authors       = ["Chris Hanks"]
  spec.email         = ["christopher.m.hanks@gmail.com"]
  spec.summary       = %q{Que for Rails}
  spec.description   = %q{Railtie, Generators and other magic to integrate the Que job queue with Rails applications.}
  spec.homepage      = 'https://github.com/chanks/que-rails'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'que', '~> 0.9'
  spec.add_dependency 'railties', '~> 4.1.0'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
end
