# frozen_string_literal: true

module Decidim
  module Tasks
    # This is the engine that runs on the public interface of `Tasks`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Tasks::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        # Add admin engine routes here
        # resources :tasks do
        #   collection do
        #     resources :exports, only: [:create]
        #   end
        # end
        # root to: "tasks#index"
      end

      def load_seed
        nil
      end
    end
  end
end
