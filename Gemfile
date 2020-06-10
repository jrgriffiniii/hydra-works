source 'https://rubygems.org'

# Specify your gem's dependencies in hydra-works.gemspec
gemspec

gem 'active-fedora', git: 'https://github.com/jrgriffiniii/active_fedora.git', branch: 'rails6-update'
gem 'hydra-derivatives', git: 'https://github.com/jrgriffiniii/hydra-derivatives.git', branch: 'rails6-update'
gem 'slop', '~> 3.6' # For byebug

group :development, :test do
  gem 'clamby'
  gem 'pry-byebug' unless ENV['CI']
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
end

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end
end
