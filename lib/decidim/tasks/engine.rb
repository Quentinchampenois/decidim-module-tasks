# frozen_string_literal: true

require "rails"
require "decidim/core"

module Decidim
  module Tasks
    # This is the engine that runs on the public interface of tasks.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Tasks

      routes do
        # Add engine routes here
        # resources :tasks
        # root to: "tasks#index"
      end

      initializer "decidim_tasks.assets" do |app|
        app.config.assets.precompile += %w(decidim_tasks_manifest.js decidim_tasks_manifest.css)
      end
    end
  end
end
