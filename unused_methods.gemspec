# frozen_string_literal: true

require_relative "lib/unused_methods/version"

Gem::Specification.new do |spec|
  spec.name = "unused_methods"
  spec.version = UnusedMethods::VERSION
  spec.authors = ["Abhiram Pai"]
  spec.email = ["abhirampai1999@gmail.com"]

  spec.summary = "Find all unused methods"
  spec.description = "Filter unused methods"
  spec.homepage = "https://github.com/abhirampai"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/abhirampai"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "bin"
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "parser"
  spec.add_dependency "slim"

  spec.add_development_dependency "bundler", ">= 1.17"
  spec.add_development_dependency "pry", ">= 0.14.2"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "rspec", ">= 3.0"
end
