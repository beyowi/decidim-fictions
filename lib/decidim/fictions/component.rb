# frozen_string_literal: true

require "decidim/components/namer"

Decidim.register_component(:fictions) do |component|
  component.engine = Decidim::Fictions::Engine
  component.admin_engine = Decidim::Fictions::AdminEngine
  component.icon = "decidim/fictions/icon.svg"

  component.on(:before_destroy) do |instance|
    raise "Can't destroy this component when there are fictions" if Decidim::Fictions::Fiction.where(component: instance).any?
  end

  component.data_portable_entities = ["Decidim::Fictions::Fiction"]

  component.newsletter_participant_entities = ["Decidim::Fictions::Fiction"]

  component.actions = %w(endorse vote create withdraw amend)

  component.query_type = "Decidim::Fictions::FictionsType"

  component.permissions_class_name = "Decidim::Fictions::Permissions"

  component.settings(:global) do |settings|
    settings.attribute :vote_limit, type: :integer, default: 0
    settings.attribute :minimum_votes_per_user, type: :integer, default: 0
    settings.attribute :fiction_limit, type: :integer, default: 0
    settings.attribute :fiction_length, type: :integer, default: 500
    settings.attribute :fiction_edit_before_minutes, type: :integer, default: 5
    settings.attribute :threshold_per_fiction, type: :integer, default: 0
    settings.attribute :can_accumulate_supports_beyond_threshold, type: :boolean, default: false
    settings.attribute :fiction_answering_enabled, type: :boolean, default: true
    settings.attribute :official_fictions_enabled, type: :boolean, default: true
    settings.attribute :comments_enabled, type: :boolean, default: true
    settings.attribute :geocoding_enabled, type: :boolean, default: false
    settings.attribute :attachments_allowed, type: :boolean, default: false
    settings.attribute :allow_card_image, type: :boolean, default: false
    settings.attribute :resources_permissions_enabled, type: :boolean, default: true
    settings.attribute :collaborative_drafts_enabled, type: :boolean, default: false
    settings.attribute :participatory_texts_enabled,
                       type: :boolean, default: false,
                       readonly: ->(context) { Decidim::Fictions::Fiction.where(component: context[:component]).any? }
    settings.attribute :amendments_enabled, type: :boolean, default: false
    settings.attribute :amendments_wizard_help_text, type: :text, translated: true, editor: true, required: false
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :new_fiction_body_template, type: :text, translated: true, editor: false, required: false
    settings.attribute :new_fiction_help_text, type: :text, translated: true, editor: true
    settings.attribute :fiction_wizard_step_1_help_text, type: :text, translated: true, editor: true
    settings.attribute :fiction_wizard_step_2_help_text, type: :text, translated: true, editor: true
    settings.attribute :fiction_wizard_step_3_help_text, type: :text, translated: true, editor: true
    settings.attribute :fiction_wizard_step_4_help_text, type: :text, translated: true, editor: true
  end

  component.settings(:step) do |settings|
    settings.attribute :endorsements_enabled, type: :boolean, default: true
    settings.attribute :endorsements_blocked, type: :boolean
    settings.attribute :votes_enabled, type: :boolean
    settings.attribute :votes_blocked, type: :boolean
    settings.attribute :votes_hidden, type: :boolean, default: false
    settings.attribute :comments_blocked, type: :boolean, default: false
    settings.attribute :creation_enabled, type: :boolean
    settings.attribute :fiction_answering_enabled, type: :boolean, default: true
    settings.attribute :publish_answers_immediately, type: :boolean, default: true
    settings.attribute :answers_with_costs, type: :boolean, default: false
    settings.attribute :amendment_creation_enabled, type: :boolean, default: true
    settings.attribute :amendment_reaction_enabled, type: :boolean, default: true
    settings.attribute :amendment_promotion_enabled, type: :boolean, default: true
    settings.attribute :amendments_visibility,
                       type: :enum, default: "all",
                       choices: -> { Decidim.config.amendments_visibility_options }
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :automatic_hashtags, type: :text, editor: false, required: false
    settings.attribute :suggested_hashtags, type: :text, editor: false, required: false
  end

  component.register_resource(:fiction) do |resource|
    resource.model_class_name = "Decidim::Fictions::Fiction"
    resource.template = "decidim/fictions/fictions/linked_fictions"
    resource.card = "decidim/fictions/fiction"
    resource.actions = %w(endorse vote amend)
    resource.searchable = true
  end

  component.register_resource(:collaborative_draft) do |resource|
    resource.model_class_name = "Decidim::Fictions::CollaborativeDraft"
    resource.card = "decidim/fictions/collaborative_draft"
  end

  component.register_stat :fictions_count, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    Decidim::Fictions::FilteredFictions.for(components, start_at, end_at).published.except_withdrawn.not_hidden.count
  end

  component.register_stat :fictions_accepted, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    Decidim::Fictions::FilteredFictions.for(components, start_at, end_at).accepted.not_hidden.count
  end

  component.register_stat :supports_count, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    fictions = Decidim::Fictions::FilteredFictions.for(components, start_at, end_at).published.not_hidden
    Decidim::Fictions::FictionVote.where(fiction: fictions).count
  end

  component.register_stat :endorsements_count, priority: Decidim::StatsRegistry::MEDIUM_PRIORITY do |components, start_at, end_at|
    fictions = Decidim::Fictions::FilteredFictions.for(components, start_at, end_at).not_hidden
    Decidim::Endorsement.where(resource_id: fictions.pluck(:id), resource_type: Decidim::Fictions::Fiction.name).count
  end

  component.register_stat :comments_count, tag: :comments do |components, start_at, end_at|
    fictions = Decidim::Fictions::FilteredFictions.for(components, start_at, end_at).published.not_hidden
    Decidim::Comments::Comment.where(root_commentable: fictions).count
  end

  component.register_stat :followers_count, tag: :followers, priority: Decidim::StatsRegistry::LOW_PRIORITY do |components, start_at, end_at|
    fictions_ids = Decidim::Fictions::FilteredFictions.for(components, start_at, end_at).published.not_hidden.pluck(:id)
    Decidim::Follow.where(decidim_followable_type: "Decidim::Fictions::Fiction", decidim_followable_id: fictions_ids).count
  end

  component.exports :fictions do |exports|
    exports.collection do |component_instance, user|
      space = component_instance.participatory_space

      collection = Decidim::Fictions::Fiction
                   .published
                   .where(component: component_instance)
                   .includes(:category, :component)

      if space.user_roles(:valuator).where(user: user).any?
        collection.with_valuation_assigned_to(user, space)
      else
        collection
      end
    end

    exports.include_in_open_data = true

    exports.serializer Decidim::Fictions::FictionSerializer
  end

  component.exports :comments do |exports|
    exports.collection do |component_instance|
      Decidim::Comments::Export.comments_for_resource(
        Decidim::Fictions::Fiction, component_instance
      )
    end

    exports.serializer Decidim::Comments::CommentSerializer
  end

  component.seeds do |participatory_space|
    admin_user = Decidim::User.find_by(
      organization: participatory_space.organization,
      email: "admin@example.org"
    )

    step_settings = if participatory_space.allows_steps?
                      { participatory_space.active_step.id => { votes_enabled: true, votes_blocked: false, creation_enabled: true } }
                    else
                      {}
                    end

    params = {
      name: Decidim::Components::Namer.new(participatory_space.organization.available_locales, :fictions).i18n_name,
      manifest_name: :fictions,
      published_at: Time.current,
      participatory_space: participatory_space,
      settings: {
        vote_limit: 0,
        collaborative_drafts_enabled: true
      },
      step_settings: step_settings
    }

    component = Decidim.traceability.perform_action!(
      "publish",
      Decidim::Component,
      admin_user,
      visibility: "all"
    ) do
      Decidim::Component.create!(params)
    end

    if participatory_space.scope
      scopes = participatory_space.scope.descendants
      global = participatory_space.scope
    else
      scopes = participatory_space.organization.scopes
      global = nil
    end

    5.times do |n|
      state, answer, state_published_at = if n > 3
                                            ["accepted", Decidim::Faker::Localized.sentence(10), Time.current]
                                          elsif n > 2
                                            ["rejected", nil, Time.current]
                                          elsif n > 1
                                            ["evaluating", nil, Time.current]
                                          elsif n.positive?
                                            ["accepted", Decidim::Faker::Localized.sentence(10), nil]
                                          else
                                            [nil, nil, nil]
                                          end

      params = {
        component: component,
        category: participatory_space.categories.sample,
        scope: Faker::Boolean.boolean(0.5) ? global : scopes.sample,
        title: Faker::Lorem.sentence(2),
        body: Faker::Lorem.paragraphs(2).join("\n"),
        state: state,
        answer: answer,
        answered_at: state.present? ? Time.current : nil,
        state_published_at: state_published_at,
        published_at: Time.current
      }

      fiction = Decidim.traceability.perform_action!(
        "publish",
        Decidim::Fictions::Fiction,
        admin_user,
        visibility: "all"
      ) do
        fiction = Decidim::Fictions::Fiction.new(params)
        fiction.add_coauthor(participatory_space.organization)
        fiction.save!
        fiction
      end

      if n.positive?
        Decidim::User.where(decidim_organization_id: participatory_space.decidim_organization_id).all.sample(n).each do |author|
          user_group = [true, false].sample ? Decidim::UserGroups::ManageableUserGroups.for(author).verified.sample : nil
          fiction.add_coauthor(author, user_group: user_group)
        end
      end

      if fiction.state.nil?
        email = "amendment-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-amend#{n}@example.org"
        name = "#{Faker::Name.name} #{participatory_space.id} #{n} amend#{n}"

        author = Decidim::User.find_or_initialize_by(email: email)
        author.update!(
          password: "password1234",
          password_confirmation: "password1234",
          name: name,
          nickname: Faker::Twitter.unique.screen_name,
          organization: component.organization,
          tos_agreement: "1",
          confirmed_at: Time.current
        )

        group = Decidim::UserGroup.create!(
          name: Faker::Name.name,
          nickname: Faker::Twitter.unique.screen_name,
          email: Faker::Internet.email,
          extended_data: {
            document_number: Faker::Code.isbn,
            phone: Faker::PhoneNumber.phone_number,
            verified_at: Time.current
          },
          decidim_organization_id: component.organization.id,
          confirmed_at: Time.current
        )

        Decidim::UserGroupMembership.create!(
          user: author,
          role: "creator",
          user_group: group
        )

        params = {
          component: component,
          category: participatory_space.categories.sample,
          scope: Faker::Boolean.boolean(0.5) ? global : scopes.sample,
          title: "#{fiction.title} #{Faker::Lorem.sentence(1)}",
          body: "#{fiction.body} #{Faker::Lorem.sentence(3)}",
          state: "evaluating",
          answer: nil,
          answered_at: Time.current,
          published_at: Time.current
        }

        emendation = Decidim.traceability.perform_action!(
          "create",
          Decidim::Fictions::Fiction,
          author,
          visibility: "public-only"
        ) do
          emendation = Decidim::Fictions::Fiction.new(params)
          emendation.add_coauthor(author, user_group: author.user_groups.first)
          emendation.save!
          emendation
        end

        Decidim::Amendment.create!(
          amender: author,
          amendable: fiction,
          emendation: emendation,
          state: "evaluating"
        )
      end

      (n % 3).times do |m|
        email = "vote-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-#{m}@example.org"
        name = "#{Faker::Name.name} #{participatory_space.id} #{n} #{m}"

        author = Decidim::User.find_or_initialize_by(email: email)
        author.update!(
          password: "password1234",
          password_confirmation: "password1234",
          name: name,
          nickname: Faker::Twitter.unique.screen_name,
          organization: component.organization,
          tos_agreement: "1",
          confirmed_at: Time.current,
          personal_url: Faker::Internet.url,
          about: Faker::Lorem.paragraph(2)
        )

        Decidim::Fictions::FictionVote.create!(fiction: fiction, author: author) unless fiction.published_state? && fiction.rejected?
        Decidim::Fictions::FictionVote.create!(fiction: emendation, author: author) if emendation
      end

      unless fiction.published_state? && fiction.rejected?
        (n * 2).times do |index|
          email = "endorsement-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-endr#{index}@example.org"
          name = "#{Faker::Name.name} #{participatory_space.id} #{n} endr#{index}"

          author = Decidim::User.find_or_initialize_by(email: email)
          author.update!(
            password: "password1234",
            password_confirmation: "password1234",
            name: name,
            nickname: Faker::Twitter.unique.screen_name,
            organization: component.organization,
            tos_agreement: "1",
            confirmed_at: Time.current
          )
          if index.even?
            group = Decidim::UserGroup.create!(
              name: Faker::Name.name,
              nickname: Faker::Twitter.unique.screen_name,
              email: Faker::Internet.email,
              extended_data: {
                document_number: Faker::Code.isbn,
                phone: Faker::PhoneNumber.phone_number,
                verified_at: Time.current
              },
              decidim_organization_id: component.organization.id,
              confirmed_at: Time.current
            )

            Decidim::UserGroupMembership.create!(
              user: author,
              role: "creator",
              user_group: group
            )
          end
          Decidim::Endorsement.create!(resource: fiction, author: author, user_group: author.user_groups.first)
        end
      end

      (n % 3).times do
        author_admin = Decidim::User.where(organization: component.organization, admin: true).all.sample

        Decidim::Fictions::FictionNote.create!(
          fiction: fiction,
          author: author_admin,
          body: Faker::Lorem.paragraphs(2).join("\n")
        )
      end

      Decidim::Comments::Seed.comments_for(fiction)

      #
      # Collaborative drafts
      #
      state = if n > 3
                "published"
              elsif n > 2
                "withdrawn"
              else
                "open"
              end
      author = Decidim::User.where(organization: component.organization).all.sample

      draft = Decidim.traceability.perform_action!("create", Decidim::Fictions::CollaborativeDraft, author) do
        draft = Decidim::Fictions::CollaborativeDraft.new(
          component: component,
          category: participatory_space.categories.sample,
          scope: Faker::Boolean.boolean(0.5) ? global : scopes.sample,
          title: Faker::Lorem.sentence(2),
          body: Faker::Lorem.paragraphs(2).join("\n"),
          state: state,
          published_at: Time.current
        )
        draft.coauthorships.build(author: participatory_space.organization)
        draft.save!
        draft
      end

      if n == 2
        author2 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author2)
        author3 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author3)
        author4 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author4)
        author5 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author5)
        author6 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author6)
      elsif n == 3
        author2 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author2)
      end

      Decidim::Comments::Seed.comments_for(draft)
    end

    Decidim.traceability.update!(
      Decidim::Fictions::CollaborativeDraft.all.sample,
      Decidim::User.where(organization: component.organization).all.sample,
      component: component,
      category: participatory_space.categories.sample,
      scope: Faker::Boolean.boolean(0.5) ? global : scopes.sample,
      title: Faker::Lorem.sentence(2),
      body: Faker::Lorem.paragraphs(2).join("\n")
    )
  end
end
