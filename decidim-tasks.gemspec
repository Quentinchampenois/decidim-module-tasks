# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/tasks/version"

Gem::Specification.new do |s|
  s.version = Decidim::Tasks.version
  s.authors = ["quentinchampenois"]
  s.email = ["26109239+Quentinchampenois@users.noreply.github.com"]
  s.license = "AGPL-3.0"
  s.homepage = "https://github.com/decidim/decidim-module-tasks"
  s.required_ruby_version = ">= 2.5"

  s.name = "decidim-tasks"
  s.summary = "A decidim tasks module"
  s.description = "Decidim module with custom tasks."

  s.files = Dir["{app,config,lib}/**/*", "LICENSE-AGPLv3.txt", "Rakefile", "README.md"]

  s.add_dependency "decidim-core", Decidim::Tasks.version
end
