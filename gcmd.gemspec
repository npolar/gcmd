# encoding: utf-8
# https://github.com/radar/guides/blob/master/gem-development.md
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
  
Gem::Specification.new do |s|
  s.name        = "gcmd"
  s.version     = "0.0.1.dev"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Conrad Helgeland", "Ruben Dens"]
  s.email       = [""]
  s.homepage    = "http://github.com/npolar/gcmd"
  s.summary     = "Ruby libray for npolar.no"
  s.description = "Ruby library for working with GCMD services and DIF"
  
  s.add_development_dependency "rspec", "~> 2.0"

  s.files        = Dir.glob("{lib}/**/*") + %w(README.md)
  #s.executables  = ['']
  s.require_paths      = ["lib"]
  git_files            = `git ls-files`.split("\n") rescue ''
  s.files              = git_files # + whatever_else
  s.test_files         = `git ls-files -- {test,spec}/*`.split("\n")
  s.require_paths      = ["lib"]

end

