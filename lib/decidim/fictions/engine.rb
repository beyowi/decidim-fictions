# frozen_string_literal: true

require "kaminari"
require "social-share-button"
require "ransack"
require "cells/rails"
require "cells-erb"
require "cell/partial"

module Decidim
  module Fictions
    # This is the engine that runs on the public interface of `decidim-fictions`.
    # It mostly handles rendering the created page associated to a participatory
    # process.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Fictions

      routes do
        resources :fictions, except: [:destroy] do
          member do
            get :compare
            get :complete
            get :edit_draft
            patch :update_draft
            get :preview
            post :publish
            delete :destroy_draft
            put :withdraw
          end
          resource :fiction_vote, only: [:create, :destroy]
          resource :fiction_widget, only: :show, path: "embed"
          resources :versions, only: [:show, :index]
        end
        resources :collaborative_drafts, except: [:destroy] do
          get :compare, on: :collection
          get :complete, on: :collection
          member do
            post :request_access, controller: "collaborative_draft_collaborator_requests"
            post :request_accept, controller: "collaborative_draft_collaborator_requests"
            post :request_reject, controller: "collaborative_draft_collaborator_requests"
            post :withdraw
            post :publish
          end
          resources :versions, only: [:show, :index]
        end
        root to: "fictions#index"
      end

      initializer "decidim_fictions.assets" do |app|
        app.config.assets.precompile += %w(decidim_fictions_manifest.js)
      end

      initializer "decidim.content_processors" do |_app|
        Decidim.configure do |config|
          config.content_processors += [:fiction]
        end
      end

      initializer "decidim_fictions.view_hooks" do
        Decidim.view_hooks.register(:participatory_space_highlighted_elements, priority: Decidim::ViewHooks::MEDIUM_PRIORITY) do |view_context|
          view_context.cell("decidim/fictions/highlighted_fictions", view_context.current_participatory_space)
        end

        if defined? Decidim::ParticipatoryProcesses
          Decidim::ParticipatoryProcesses.view_hooks.register(:process_group_highlighted_elements, priority: Decidim::ViewHooks::MEDIUM_PRIORITY) do |view_context|
            published_components = Decidim::Component.where(participatory_space: view_context.participatory_processes).published
            fictions = Decidim::Fictions::Fiction.published.not_hidden.except_withdrawn
                                                    .where(component: published_components)
                                                    .order_randomly(rand * 2 - 1)
                                                    .limit(Decidim::Fictions.config.process_group_highlighted_fictions_limit)

            next unless fictions.any?

            view_context.extend Decidim::ResourceReferenceHelper
            view_context.extend Decidim::Fictions::ApplicationHelper
            view_context.render(
              partial: "decidim/participatory_processes/participatory_process_groups/highlighted_fictions",
              locals: {
                fictions: fictions
              }
            )
          end
        end
      end

      initializer "decidim_changes" do
        Decidim::SettingsChange.subscribe "surveys" do |changes|
          Decidim::Fictions::SettingsChangeJob.perform_later(
            changes[:component_id],
            changes[:previous_settings],
            changes[:current_settings]
          )
        end
      end

      initializer "decidim_fictions.mentions_listener" do
        Decidim::Comments::CommentCreation.subscribe do |data|
          fictions = data.dig(:metadatas, :fiction).try(:linked_fictions)
          Decidim::Fictions::NotifyFictionsMentionedJob.perform_later(data[:comment_id], fictions) if fictions
        end
      end

      # Subscribes to ActiveSupport::Notifications that may affect a Fiction.
      initializer "decidim_fictions.subscribe_to_events" do
        # when a fiction is linked from a result
        event_name = "decidim.resourceable.included_fictions.created"
        ActiveSupport::Notifications.subscribe event_name do |_name, _started, _finished, _unique_id, data|
          payload = data[:this]
          if payload[:from_type] == Decidim::Accountability::Result.name && payload[:to_type] == Fiction.name
            fiction = Fiction.find(payload[:to_id])
            fiction.update(state: "accepted", state_published_at: Time.current)
          end
        end
      end

      initializer "decidim_fictions.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Fictions::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Fictions::Engine.root}/app/views") # for fiction partials
      end

      initializer "decidim_fictions.add_badges" do
        Decidim::Gamification.register_badge(:fictions) do |badge|
          badge.levels = [1, 5, 10, 30, 60]

          badge.valid_for = [:user, :user_group]

          badge.reset = lambda { |model|
            if model.is_a?(User)
              Decidim::Coauthorship.where(
                coauthorable_type: "Decidim::Fictions::Fiction",
                author: model,
                user_group: nil
              ).count
            elsif model.is_a?(UserGroup)
              Decidim::Coauthorship.where(
                coauthorable_type: "Decidim::Fictions::Fiction",
                user_group: model
              ).count
            end
          }
        end

        Decidim::Gamification.register_badge(:accepted_fictions) do |badge|
          badge.levels = [1, 5, 15, 30, 50]

          badge.valid_for = [:user, :user_group]

          badge.reset = lambda { |model|
            fiction_ids = if model.is_a?(User)
                             Decidim::Coauthorship.where(
                               coauthorable_type: "Decidim::Fictions::Fiction",
                               author: model,
                               user_group: nil
                             ).select(:coauthorable_id)
                           elsif model.is_a?(UserGroup)
                             Decidim::Coauthorship.where(
                               coauthorable_type: "Decidim::Fictions::Fiction",
                               user_group: model
                             ).select(:coauthorable_id)
                           end

            Decidim::Fictions::Fiction.where(id: fiction_ids).accepted.count
          }
        end

        Decidim::Gamification.register_badge(:fiction_votes) do |badge|
          badge.levels = [5, 15, 50, 100, 500]

          badge.reset = lambda { |user|
            Decidim::Fictions::FictionVote.where(author: user).select(:decidim_fiction_id).distinct.count
          }
        end
      end

      initializer "decidim_fictions.register_metrics" do
        Decidim.metrics_registry.register(:fictions) do |metric_registry|
          metric_registry.manager_class = "Decidim::Fictions::Metrics::FictionsMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: true
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 2
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_registry.register(:accepted_fictions) do |metric_registry|
          metric_registry.manager_class = "Decidim::Fictions::Metrics::AcceptedFictionsMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: false
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 3
            settings.attribute :stat_block, type: :string, default: "small"
          end
        end

        Decidim.metrics_registry.register(:fiction_votes) do |metric_registry|
          metric_registry.manager_class = "Decidim::Fictions::Metrics::VotesMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: true
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 3
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_registry.register(:fiction_endorsements) do |metric_registry|
          metric_registry.manager_class = "Decidim::Fictions::Metrics::EndorsementsMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: false
            settings.attribute :scopes, type: :array, default: %w(participatory_process)
            settings.attribute :weight, type: :integer, default: 4
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_operation.register(:participants, :fictions) do |metric_operation|
          metric_operation.manager_class = "Decidim::Fictions::Metrics::FictionParticipantsMetricMeasure"
        end
        Decidim.metrics_operation.register(:followers, :fictions) do |metric_operation|
          metric_operation.manager_class = "Decidim::Fictions::Metrics::FictionFollowersMetricMeasure"
        end
      end
    end
  end
end
