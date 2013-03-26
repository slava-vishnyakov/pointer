# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pointer/version'

Gem::Specification.new do |spec|
  spec.name          = "pointer"
  spec.version       = Pointer::VERSION
  spec.authors       = ["Slava Vishnyakov"]
  spec.email         = ["bomboze@gmail.com"]
  spec.description   = %q{Quick deploy}
  spec.summary       = %q{Quick deploy}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_dependency "net-ssh"
  spec.add_dependency "net-scp"
  spec.add_dependency "colorize"
  spec.add_dependency "active_support"
end
