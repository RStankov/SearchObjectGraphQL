# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'English'
require 'search_object/plugin/graphql/version'

Gem::Specification.new do |spec|
  spec.name          = 'search_object_graphql'
  spec.version       = SearchObject::Plugin::Graphql::VERSION
  spec.authors       = ['Radoslav Stankov']
  spec.email         = ['rstankov@gmail.com']
  spec.description   = 'Search Object plugin to working with GraphQL'
  spec.summary       = 'Maps search objects to GraphQL resolvers'
  spec.homepage      = 'https://github.com/RStankov/SearchObjectGraphQL'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($RS)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'graphql', '~> 1.8'
  spec.add_dependency 'search_object', '~> 1.2.2'

  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'rubocop', '0.62.0'
  spec.add_development_dependency 'rubocop-rspec', '1.31.0'
end
