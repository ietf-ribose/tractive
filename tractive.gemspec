# frozen_string_literal: true

require_relative "lib/tractive/version"

Gem::Specification.new do |spec|
  spec.name          = "tractive"
  spec.version       = Tractive::VERSION
  spec.authors       = ["Ribose"]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "Exporting tool for Trac"
  # spec.description   = "TODO: Write a longer description or delete this line."
  spec.homepage      = "https://github.com/ietf-ribose/tractive"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ietf-ribose/tractive"
  spec.metadata["changelog_uri"] = "https://github.com/ietf-ribose/tractive"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "graphql", "1.13.3"
  spec.add_dependency "graphql-client"
  spec.add_dependency "mysql2"
  spec.add_dependency "ox"
  spec.add_dependency "rest-client"
  spec.add_dependency "sequel"
  spec.add_dependency "sqlite3"
  spec.add_dependency "thor"

  spec.add_development_dependency "pry"
end
