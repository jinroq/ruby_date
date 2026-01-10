# frozen_string_literal: true

require_relative "lib/ruby_date/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_date"
  spec.version = RubyDate::VERSION
  spec.authors = ["jinroq"]
  spec.email = []

  spec.summary = "date library for Ruby"
  spec.description = "RubyDate is a pure Ruby replacement for the official Ruby date library, which was implemented in C."
  spec.homepage = "https://github.com/jinroq/ruby_date/"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage + "/blob/master/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
