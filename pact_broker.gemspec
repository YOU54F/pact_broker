# -*- encoding: utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pact_broker/version"


Gem::Specification.new do |gem|

  gem.name          = "pact_broker"
  gem.version       = PactBroker::VERSION
  gem.authors       = ["Bethany Skurrie", "Sergei Matheson", "Warner Godfrey"]
  gem.email         = ["bskurrie@dius.com.au", "serge.matheson@rea-group.com", "warner@warnergodfrey.com"]
  gem.description   = %q{A server that stores and returns pact files generated by the pact gem. It enables head/prod cross testing of the consumer and provider projects.}
  gem.summary       = %q{See description}
  gem.homepage      = "https://github.com/pact-foundation/pact_broker"

  gem.required_ruby_version = ">= 2.7.0"

  gem.files         = begin
                        if Dir.exist?(".git")
                          Dir.chdir(File.expand_path(__dir__)) do
                            include_patterns = %w[lib/**/* db/**/* docs/**/*.md public/**/* vendor/**/* LICENSE.txt README.md CHANGELOG.md Gemfile pact_broker.gemspec]
                            exclude_patterns = %w[db/test/**/* lib/**/*/README.md]
                            include_list = include_patterns.flat_map{ | pattern | Dir.glob(pattern) } - exclude_patterns.flat_map{ | pattern | Dir.glob(pattern) }

                            `git ls-files -z`.split("\x0") & include_list
                          end
                        else
                          # Can't remember why this is ever needed
                          root_path      = File.dirname(__FILE__)
                          all_files      = Dir.chdir(root_path) { Dir.glob("**/{*,.*}") }
                          all_files.reject! { |file| [".", ".."].include?(File.basename(file)) || File.directory?(file)}
                          gitignore_path = File.join(root_path, ".gitignore")
                          gitignore      = File.readlines(gitignore_path)
                          gitignore.map!    { |line| line.chomp.strip }
                          gitignore.reject! { |line| line.empty? || line =~ /^(#|!)/ }

                          all_files.reject do |file|
                            gitignore.any? do |ignore|
                              file.start_with?(ignore) ||
                                File.fnmatch(ignore, file, File::FNM_PATHNAME) ||
                                File.fnmatch(ignore, File.basename(file), File::FNM_PATHNAME)
                            end
                          end
                        end
                      end
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.license       = "MIT"

  gem.add_runtime_dependency "json", "~> 2.3"
  gem.add_runtime_dependency "psych", "~> 5.0"
  gem.add_runtime_dependency "roar", "~> 1.1"
  gem.add_runtime_dependency "dry-validation", "~> 1.8"
  gem.add_runtime_dependency "reform", "~> 2.6"
  gem.add_runtime_dependency "sequel", "~> 5.28"
  gem.add_runtime_dependency "webmachine", ">= 2.0.0.beta", "< 3.0"
  gem.add_runtime_dependency "webrick", "~> 1.8" # webmachine requires webrick, but doesn't declare it as a dependency :shrug:
  gem.add_runtime_dependency "semver2", "~> 3.4.2"
  gem.add_runtime_dependency "rack", ">= 2.2.3", "~> 2.2" # TODO update to 3
  gem.add_runtime_dependency "redcarpet", ">= 3.5.1", "~>3.5"
  gem.add_runtime_dependency "pact-support" , "~> 1.16", ">= 1.16.4"
  gem.add_runtime_dependency "padrino-core", ">= 0.14.3", "~> 0.14"
  gem.add_runtime_dependency "sinatra", "~> 3.0"
  gem.add_runtime_dependency "haml", "~>5.0"
  gem.add_runtime_dependency "sucker_punch", "~>3.0"
  gem.add_runtime_dependency "rack-protection", "~> 3.0"
  gem.add_runtime_dependency "table_print", "~> 1.5"
  gem.add_runtime_dependency "semantic_logger", "~> 4.11"
  gem.add_runtime_dependency "sanitize", "~> 6.0"
  gem.add_runtime_dependency "wisper", "~> 2.0"
  gem.add_runtime_dependency "anyway_config", "~> 2.1"
  gem.add_runtime_dependency "request_store", "~> 1.5"
  gem.add_runtime_dependency "moments", "~> 0.2"
end
