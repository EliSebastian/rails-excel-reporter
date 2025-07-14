require_relative 'lib/rails_excel_reporter/version'

Gem::Specification.new do |spec|
  spec.name          = 'rails-excel-reporter'
  spec.version       = RailsExcelReporter::VERSION
  spec.authors       = ['Elí Sebastian Herrera Aguilar']
  spec.email         = ['esrbastianherrera@gmail.com']

  spec.summary       = 'Generate Excel reports (.xlsx) in Rails with a simple DSL'
  spec.description   = 'A Ruby gem that integrates seamlessly with Ruby on Rails to generate Excel reports using a simple DSL. Features include streaming, styling, callbacks, and Rails helpers.'
  spec.homepage      = 'https://github.com/EliSebastian/rails-excel-reporter.git'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new '>= 3.1.0'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/EliSebastian/rails-excel-reporter.git'
  spec.metadata['changelog_uri'] = 'https://github.com/EliSebastian/rails-excel-reporter.git/blob/main/CHANGELOG.md'

  spec.files = Dir['{lib,spec}/**/*', '*.md', '*.gemspec', 'Gemfile*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 7.0'
  spec.add_dependency 'caxlsx', '~> 4.0'
  spec.add_dependency 'rails', '>= 7.0'

  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-rails', '~> 5.0'
  spec.add_development_dependency 'simplecov', '~> 0.21'
  spec.add_development_dependency 'sqlite3', '~> 1.4'
  spec.add_development_dependency 'yard', '~> 0.9'
end
