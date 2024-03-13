Gem::Specification.new do |spec|
  spec.name          = "pr_ai_gen"
  spec.version       = "0.2.0"
  spec.authors       = ["Lucas Stoller"]
  spec.email         = ["l.s.stoller@gmail.com"]
  spec.summary       = "A CLI tool to generate pull requests using OpenAI"
  spec.description   = "This tool automates the process of creating pull requests by using OpenAI to generate the content based on the differences between two git branches."
  spec.homepage      = "https://theright.dev"

  spec.files         = `git ls-files`.split($/)
  spec.bindir        = "exe"
  spec.executables   = spec.executables = ['pr_ai_gen']
  spec.require_paths = ["lib"]

  spec.add_dependency "git", "~> 1.19.1"
  spec.add_dependency "openai"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
end