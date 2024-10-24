require_relative "lib/constraint_validations/version"

Gem::Specification.new do |spec|
  spec.name        = "constraint_validations"
  spec.version     = ConstraintValidations::VERSION
  spec.authors     = ["Sean Doyle"]
  spec.email       = ["sean.p.doyle24@gmail.com"]
  spec.homepage    = "https://github.com/seanpdoyle/constraint_validations"
  spec.summary     = "Integrate ActiveModel::Validations, ActionView, and Browser-provided Constraint Validation API"
  spec.description = ""
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/seanpdoyle/constraint_validations"
  spec.metadata["changelog_uri"] = "https://github.com/seanpdoyle/constraint_validations/blob/main/CHANGELOG.md"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "actionview", ">= 7.1.0"
  spec.add_dependency "railties", ">= 7.1.0"
  spec.add_dependency "html5_validators"
end
