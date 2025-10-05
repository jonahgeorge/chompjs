Gem::Specification.new do |spec|
  spec.name          = "chompjs"
  spec.version       = "1.4.0"
  spec.authors       = ["Mariusz Obajtek"]
  spec.email         = ["nykakin@gmail.com"]

  spec.summary       = "Parsing JavaScript objects into Ruby hashes"
  spec.description   = "Transforms JavaScript objects into Ruby data structures"
  spec.homepage      = "https://github.com/Nykakin/chompjs"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Nykakin/chompjs"

  spec.files = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_dependency "json", "~> 2.0"
end
