# frozen_string_literal: true

module Decidim
  module Fictions
    FictionType = GraphQL::ObjectType.define do
      name "FictionsFiction"
      description "A fiction"

      interfaces [
        -> { Decidim::Comments::CommentableInterface },
        -> { Decidim::Core::CoauthorableInterface },
        -> { Decidim::Core::CategorizableInterface },
        -> { Decidim::Core::ScopableInterface },
        -> { Decidim::Core::AttachableInterface },
        -> { Decidim::Core::FingerprintInterface },
        -> { Decidim::Core::AmendableInterface },
        -> { Decidim::Core::AmendableEntityInterface },
        -> { Decidim::Core::TraceableInterface },
        -> { Decidim::Core::EndorsableInterface },
        -> { Decidim::Core::TimestampsInterface }
      ]

      field :id, !types.ID
      field :title, !types.String, "This fiction's title"
      field :body, types.String, "This fiction's body"
      field :address, types.String, "The physical address (location) of this fiction"
      field :coordinates, Decidim::Core::CoordinatesType, "Physical coordinates for this fiction" do
        resolve ->(fiction, _args, _ctx) {
          [fiction.latitude, fiction.longitude]
        }
      end
      field :reference, types.String, "This fiction's unique reference"
      field :state, types.String, "The answer status in which fiction is in"
      field :answer, Decidim::Core::TranslatedFieldType, "The answer feedback for the status for this fiction"

      field :answeredAt, Decidim::Core::DateTimeType do
        description "The date and time this fiction was answered"
        property :answered_at
      end

      field :publishedAt, Decidim::Core::DateTimeType do
        description "The date and time this fiction was published"
        property :published_at
      end

      field :participatoryTextLevel, types.String do
        description "If it is a participatory text, the level indicates the type of paragraph"
        property :participatory_text_level
      end
      field :position, types.Int, "Position of this fiction in the participatory text"

      field :official, types.Boolean, "Whether this fiction is official or not", property: :official?
      field :createdInMeeting, types.Boolean, "Whether this fiction comes from a meeting or not", property: :official_meeting?
      field :meeting, Decidim::Meetings::MeetingType do
        description "If the fiction comes from a meeting, the related meeting"
        resolve ->(fiction, _, _) {
          fiction.authors.first if fiction.official_meeting?
        }
      end

      field :voteCount, types.Int do
        description "The total amount of votes the fiction has received"
        resolve ->(fiction, _args, _ctx) {
          current_component = fiction.component
          fiction.fiction_votes_count unless current_component.current_settings.votes_hidden?
        }
      end
    end
  end
end
