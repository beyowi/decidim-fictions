# frozen_string_literal: true

module Decidim
  module Fictions
    # This is the engine that runs on the public interface of `decidim-fictions`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Fictions::Admin

      paths["db/migrate"] = nil
      paths["lib/tasks"] = nil

      routes do
        resources :fictions, only: [:show, :index, :new, :create, :edit, :update] do
          resources :valuation_assignments, only: [:destroy]
          collection do
            post :update_category
            post :publish_answers
            post :update_scope
            resource :fictions_import, only: [:new, :create]
            resource :fictions_merge, only: [:create]
            resource :fictions_split, only: [:create]
            resource :valuation_assignment, only: [:create, :destroy]
          end
          resources :fiction_answers, only: [:edit, :update]
          resources :fiction_notes, only: [:create]
        end

        resources :participatory_texts, only: [:index] do
          collection do
            get :new_import
            post :import
            patch :import
            post :update
            post :discard
          end
        end

        root to: "fictions#index"
      end

      initializer "decidim_fictions.admin_assets" do |app|
        app.config.assets.precompile += %w(admin/decidim_fictions_manifest.js)
      end

      def load_seed
        nil
      end
    end
  end
end
