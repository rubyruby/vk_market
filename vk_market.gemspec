# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vk_market/version'

Gem::Specification.new do |spec|
  spec.name          = 'vk_market'
  spec.version       = VkMarket::VERSION
  spec.authors       = ['Ruslan']
  spec.email         = ['ruslan@vetov.ru']

  spec.summary       = 'VK Market sync gem'
  spec.description   = 'Sync Vk market products with your own database'
  spec.homepage      = 'http://www.13f.ru'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'http://gemserver.vetov.com'
  else
    raise 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'mechanize', '~> 2.7.4'
  spec.add_development_dependency 'vkontakte_api', '~> 1.4.3'
end
