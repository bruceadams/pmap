# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'pmap/version'

Gem::Specification.new do |s|
  s.name        = 'pmap'
  s.version     = Pmap::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Bruce Adams', 'Jake Goulding']
  s.email       = ['bruce.adams@acm.org', 'jake.goulding@gmail.com']
  s.homepage    = 'https://github.com/bruceadams/pmap'
  s.summary     = %q{Add parallel methods into Enumerable: pmap and peach}
  s.description = %q{Add parallel methods into Enumerable: pmap and peach}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
  s.add_development_dependency 'test-unit'
end
