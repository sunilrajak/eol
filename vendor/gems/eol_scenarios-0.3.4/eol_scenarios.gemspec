# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{eol_scenarios}
  s.version = "0.3.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jeremy Rice"]
  s.date = %q{2010-06-10}
  s.description = %q{Based on openrain-scenarios, q.v.  Depends on hard-to-find gems at the moment: remi-indifferent-variable-hash and remi-simplecli}
  s.email = %q{jrice.blue@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "eol_scenarios.gemspec",
     "examples/additional_scenarios/load_me.rb",
     "examples/additional_scenarios/load_me_too.rb",
     "examples/more_scenarios/foo.rb",
     "examples/scenarios/first.rb",
     "examples/testing_dependencies/load_more_stuff.rb",
     "examples/testing_dependencies/load_stuff.rb",
     "examples/yaml_frontmatter/yaml_in_header.rb",
     "lib/eol_scenarios.rb",
     "lib/eol_scenarios/eol_scenario.rb",
     "lib/eol_scenarios/eol_scenarios.rb",
     "lib/eol_scenarios/spec.rb",
     "lib/eol_scenarios/tasks.rb",
     "rails_generators/scenario/USAGE",
     "rails_generators/scenario/scenario_generator.rb",
     "rails_generators/scenario/templates/scenario.erb",
     "spec/scenario_spec.rb",
     "spec/scenario_spec_spec.rb",
     "spec/scenarios_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/JRice/eol_scenarios}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Execute arbitrary blocks of ruby code for loading testing scenarios}
  s.test_files = [
    "spec/scenario_spec.rb",
     "spec/scenario_spec_spec.rb",
     "spec/scenarios_spec.rb",
     "spec/spec_helper.rb",
     "examples/additional_scenarios/load_me.rb",
     "examples/additional_scenarios/load_me_too.rb",
     "examples/more_scenarios/foo.rb",
     "examples/scenarios/first.rb",
     "examples/testing_dependencies/load_more_stuff.rb",
     "examples/testing_dependencies/load_stuff.rb",
     "examples/yaml_frontmatter/yaml_in_header.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 1.2.9"])
    else
      s.add_dependency(%q<rspec>, [">= 1.2.9"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 1.2.9"])
  end
end

