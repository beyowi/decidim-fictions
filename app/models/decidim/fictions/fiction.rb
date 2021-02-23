# frozen_string_literal: true

module Decidim
  module Fictions
    # The data store for a Fiction in the Decidim::Fictions component.
    class Fiction < Fictions::ApplicationRecord
      include Decidim::Resourceable
      include Decidim::Coauthorable
      include Decidim::HasComponent
      include Decidim::ScopableComponent
      include Decidim::HasReference
      include Decidim::HasCategory
      include Decidim::Reportable
      include Decidim::HasAttachments
      include Decidim::Followable
      include Decidim::Fictions::CommentableFiction
      include Decidim::Searchable
      include Decidim::Traceable
      include Decidim::Loggable
      include Decidim::Fingerprintable
      include Decidim::DataPortability
      include Decidim::Hashtaggable
      include Decidim::Fictions::ParticipatoryTextSection
      include Decidim::Amendable
      include Decidim::NewsletterParticipant
      include Decidim::Randomable
      include Decidim::Endorsable
      include Decidim::Fictions::Valuatable

      POSSIBLE_STATES = %w(not_answered evaluating accepted rejected withdrawn).freeze

      fingerprint fields: [:title, :body]

      amendable(
        fields: [:title, :body],
        form: "Decidim::Fictions::FictionForm"
      )

      component_manifest_name "fictions"

      has_many :votes,
               -> { final },
               foreign_key: "decidim_fiction_id",
               class_name: "Decidim::Fictions::FictionVote",
               dependent: :destroy,
               counter_cache: "fiction_votes_count"

      has_many :notes, foreign_key: "decidim_fiction_id", class_name: "FictionNote", dependent: :destroy, counter_cache: "fiction_notes_count"

      validates :title, :body, presence: true

      geocoded_by :address, http_headers: ->(fiction) { { "Referer" => fiction.component.organization.host } }

      scope :answered, -> { where.not(answered_at: nil) }
      scope :not_answered, -> { where(answered_at: nil) }

      scope :state_not_published, -> { where(state_published_at: nil) }
      scope :state_published, -> { where.not(state_published_at: nil).where.not(state: nil) }

      scope :accepted, -> { state_published.where(state: "accepted") }
      scope :rejected, -> { state_published.where(state: "rejected") }
      scope :evaluating, -> { state_published.where(state: "evaluating") }
      scope :withdrawn, -> { where(state: "withdrawn") }
      scope :except_rejected, -> { where.not(state: "rejected").or(state_not_published) }
      scope :except_withdrawn, -> { where.not(state: "withdrawn").or(where(state: nil)) }
      scope :drafts, -> { where(published_at: nil) }
      scope :except_drafts, -> { where.not(published_at: nil) }
      scope :published, -> { where.not(published_at: nil) }
      scope :official_origin, lambda {
        where.not(coauthorships_count: 0)
             .joins(:coauthorships)
             .where(decidim_coauthorships: { decidim_author_type: "Decidim::Organization" })
      }
      scope :citizens_origin, lambda {
        where.not(coauthorships_count: 0)
             .joins(:coauthorships)
             .where.not(decidim_coauthorships: { decidim_author_type: "Decidim::Organization" })
      }
      scope :user_group_origin, lambda {
        where.not(coauthorships_count: 0)
             .joins(:coauthorships)
             .where(decidim_coauthorships: { decidim_author_type: "Decidim::UserBaseEntity" })
             .where.not(decidim_coauthorships: { decidim_user_group_id: nil })
      }
      scope :meeting_origin, lambda {
        where.not(coauthorships_count: 0)
             .joins(:coauthorships)
             .where(decidim_coauthorships: { decidim_author_type: "Decidim::Meetings::Meeting" })
      }
      scope :sort_by_valuation_assignments_count_asc, lambda {
        order(sort_by_valuation_assignments_count_nulls_last_query + "ASC NULLS FIRST")
      }

      scope :sort_by_valuation_assignments_count_desc, lambda {
        order(sort_by_valuation_assignments_count_nulls_last_query + "DESC NULLS LAST")
      }

      def self.with_valuation_assigned_to(user, space)
        valuator_roles = space.user_roles(:valuator).where(user: user)

        includes(:valuation_assignments)
          .where(decidim_fictions_valuation_assignments: { valuator_role_id: valuator_roles })
      end

      acts_as_list scope: :decidim_component_id

      searchable_fields({
                          scope_id: :decidim_scope_id,
                          participatory_space: { component: :participatory_space },
                          D: :search_body,
                          A: :search_title,
                          datetime: :published_at
                        },
                        index_on_create: ->(fiction) { fiction.official? },
                        index_on_update: ->(fiction) { fiction.visible? })

      def self.log_presenter_class_for(_log)
        Decidim::Fictions::AdminLog::FictionPresenter
      end

      # Returns a collection scoped by an author.
      # Overrides this method in DataPortability to support Coauthorable.
      def self.user_collection(author)
        return unless author.is_a?(Decidim::User)

        joins(:coauthorships)
          .where("decidim_coauthorships.coauthorable_type = ?", name)
          .where("decidim_coauthorships.decidim_author_id = ? AND decidim_coauthorships.decidim_author_type = ? ", author.id, author.class.base_class.name)
      end

      def self.retrieve_fictions_for(component)
        Decidim::Fictions::Fiction.where(component: component).joins(:coauthorships)
                                    .includes(:votes, :endorsements)
                                    .where(decidim_coauthorships: { decidim_author_type: "Decidim::UserBaseEntity" })
                                    .not_hidden
                                    .published
                                    .except_withdrawn
      end

      def self.newsletter_participant_ids(component)
        fictions = retrieve_fictions_for(component).uniq

        coauthors_recipients_ids = fictions.map { |p| p.notifiable_identities.pluck(:id) }.flatten.compact.uniq

        participants_has_voted_ids = Decidim::Fictions::FictionVote.joins(:fiction).where(fiction: fictions).joins(:author).map(&:decidim_author_id).flatten.compact.uniq

        endorsements_participants_ids = Decidim::Endorsement.where(resource: fictions)
                                                            .where(decidim_author_type: "Decidim::UserBaseEntity")
                                                            .map(&:decidim_author_id).flatten.compact.uniq

        commentators_ids = Decidim::Comments::Comment.user_commentators_ids_in(fictions)

        (endorsements_participants_ids + participants_has_voted_ids + coauthors_recipients_ids + commentators_ids).flatten.compact.uniq
      end

      # Public: Updates the vote count of this fiction.
      #
      # Returns nothing.
      # rubocop:disable Rails/SkipsModelValidations
      def update_votes_count
        update_columns(fiction_votes_count: votes.count)
      end
      # rubocop:enable Rails/SkipsModelValidations

      # Public: Check if the user has voted the fiction.
      #
      # Returns Boolean.
      def voted_by?(user)
        FictionVote.where(fiction: self, author: user).any?
      end

      # Public: Checks if the fiction has been published or not.
      #
      # Returns Boolean.
      def published?
        published_at.present?
      end

      # Public: Returns the published state of the fiction.
      #
      # Returns Boolean.
      def state
        return amendment.state if emendation?
        return nil unless published_state? || withdrawn?

        super
      end

      # This is only used to define the setter, as the getter will be overriden below.
      alias_attribute :internal_state, :state

      # Public: Returns the internal state of the fiction.
      #
      # Returns Boolean.
      def internal_state
        return amendment.state if emendation?

        self[:state]
      end

      # Public: Checks if the organization has published the state for the fiction.
      #
      # Returns Boolean.
      def published_state?
        emendation? || state_published_at.present?
      end

      # Public: Checks if the organization has given an answer for the fiction.
      #
      # Returns Boolean.
      def answered?
        answered_at.present?
      end

      # Public: Checks if the author has withdrawn the fiction.
      #
      # Returns Boolean.
      def withdrawn?
        internal_state == "withdrawn"
      end

      # Public: Checks if the organization has accepted a fiction.
      #
      # Returns Boolean.
      def accepted?
        state == "accepted"
      end

      # Public: Checks if the organization has rejected a fiction.
      #
      # Returns Boolean.
      def rejected?
        state == "rejected"
      end

      # Public: Checks if the organization has marked the fiction as evaluating it.
      #
      # Returns Boolean.
      def evaluating?
        state == "evaluating"
      end

      # Public: Overrides the `reported_content_url` Reportable concern method.
      def reported_content_url
        ResourceLocatorPresenter.new(self).url
      end

      # Public: Whether the fiction is official or not.
      def official?
        authors.first.is_a?(Decidim::Organization)
      end

      # Public: Whether the fiction is created in a meeting or not.
      def official_meeting?
        authors.first.class.name == "Decidim::Meetings::Meeting"
      end

      # Public: The maximum amount of votes allowed for this fiction.
      #
      # Returns an Integer with the maximum amount of votes, nil otherwise.
      def maximum_votes
        maximum_votes = component.settings.threshold_per_fiction
        return nil if maximum_votes.zero?

        maximum_votes
      end

      # Public: The maximum amount of votes allowed for this fiction. 0 means infinite.
      #
      # Returns true if reached, false otherwise.
      def maximum_votes_reached?
        return false unless maximum_votes

        votes.count >= maximum_votes
      end

      # Public: Can accumulate more votres than maximum for this fiction.
      #
      # Returns true if can accumulate, false otherwise
      def can_accumulate_supports_beyond_threshold
        component.settings.can_accumulate_supports_beyond_threshold
      end

      # Checks whether the user can edit the given fiction.
      #
      # user - the user to check for authorship
      def editable_by?(user)
        return true if draft?

        !published_state? && within_edit_time_limit? && !copied_from_other_component? && created_by?(user)
      end

      # Checks whether the user can withdraw the given fiction.
      #
      # user - the user to check for withdrawability.
      def withdrawable_by?(user)
        user && !withdrawn? && authored_by?(user) && !copied_from_other_component?
      end

      # Public: Whether the fiction is a draft or not.
      def draft?
        published_at.nil?
      end

      # method for sort_link by number of comments
      ransacker :commentable_comments_count do
        query = <<-SQL
        (SELECT COUNT(decidim_comments_comments.id)
         FROM decidim_comments_comments
         WHERE decidim_comments_comments.decidim_commentable_id = decidim_fictions_fictions.id
         AND decidim_comments_comments.decidim_commentable_type = 'Decidim::Fictions::Fiction'
         GROUP BY decidim_comments_comments.decidim_commentable_id
         )
        SQL
        Arel.sql(query)
      end

      # Defines the base query so that ransack can actually sort by this value
      def self.sort_by_valuation_assignments_count_nulls_last_query
        <<-SQL
        (
          SELECT COUNT(decidim_fictions_valuation_assignments.id)
          FROM decidim_fictions_valuation_assignments
          WHERE decidim_fictions_valuation_assignments.decidim_fiction_id = decidim_fictions_fictions.id
          GROUP BY decidim_fictions_valuation_assignments.decidim_fiction_id
        )
        SQL
      end

      # method to filter by assigned valuator role ID
      def self.valuator_role_ids_has(value)
        query = <<-SQL
        :value = any(
          (SELECT decidim_fictions_valuation_assignments.valuator_role_id
          FROM decidim_fictions_valuation_assignments
          WHERE decidim_fictions_valuation_assignments.decidim_fiction_id = decidim_fictions_fictions.id
          )
        )
        SQL
        where(query, value: value)
      end

      def self.ransackable_scopes(_auth = nil)
        [:valuator_role_ids_has]
      end

      ransacker :state_published do
        Arel.sql("CASE
          WHEN EXISTS (
            SELECT 1 FROM decidim_amendments
            WHERE decidim_amendments.decidim_emendation_type = 'Decidim::Fictions::Fiction'
            AND decidim_amendments.decidim_emendation_id = decidim_fictions_fictions.id
          ) THEN 0
          WHEN state_published_at IS NULL AND answered_at IS NOT NULL THEN 2
          WHEN state_published_at IS NOT NULL THEN 1
          ELSE 0 END
        ")
      end

      ransacker :state do
        Arel.sql("CASE WHEN state = 'withdrawn' THEN 'withdrawn' WHEN state_published_at IS NULL THEN NULL ELSE state END")
      end

      ransacker :id_string do
        Arel.sql(%{cast("decidim_fictions_fictions"."id" as text)})
      end

      ransacker :is_emendation do |_parent|
        query = <<-SQL
        (
          SELECT EXISTS (
            SELECT 1 FROM decidim_amendments
            WHERE decidim_amendments.decidim_emendation_type = 'Decidim::Fictions::Fiction'
            AND decidim_amendments.decidim_emendation_id = decidim_fictions_fictions.id
          )
        )
        SQL
        Arel.sql(query)
      end

      def self.export_serializer
        Decidim::Fictions::FictionSerializer
      end

      def self.data_portability_images(user)
        user_collection(user).map { |p| p.attachments.collect(&:file) }
      end

      # Public: Overrides the `allow_resource_permissions?` Resourceable concern method.
      def allow_resource_permissions?
        component.settings.resources_permissions_enabled
      end

      # Checks whether the fiction is inside the time window to be editable or not once published.
      def within_edit_time_limit?
        return true if draft?

        limit = updated_at + component.settings.fiction_edit_before_minutes.minutes
        Time.current < limit
      end

      def process_amendment_state_change!
        return unless %w(accepted rejected evaluating withdrawn).member?(amendment.state)

        PaperTrail.request(enabled: false) do
          update!(
            state: amendment.state,
            state_published_at: Time.current
          )
        end
      end

      private

      def copied_from_other_component?
        linked_resources(:fictions, "copied_from_component").any?
      end
    end
  end
end