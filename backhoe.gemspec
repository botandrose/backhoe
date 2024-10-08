
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "backhoe/version"

Gem::Specification.new do |spec|
  spec.name          = "backhoe"
  spec.version       = Backhoe::VERSION
  spec.authors       = ["Micah Geisel"]
  spec.email         = ["micah@botandrose.com"]

  spec.summary       = "Dump and load current database to and from a file."
  spec.description   = "Dump and load current database to and from a file."
  spec.homepage      = "https://github.com/botandrose/backhoe"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "webrick"
end
