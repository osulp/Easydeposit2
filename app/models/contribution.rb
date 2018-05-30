class Contribution < ActiveRecord::Base
  # Allowed values for visibility
  VISIBILITY_VALUES = %w(public private).freeze
  # Allowed values for status
  STATUS_VALUES = %w(approved denied new unknown).freeze

  belongs_to :publication, required: true, inverse_of: :contributions
  belongs_to :author, required: true, inverse_of: :contributions

  has_one :publication_identifier, -> { where("publication_identifiers.identifier_type = 'PublicationItemId'") },
          class_name: 'PublicationIdentifier',
          foreign_key: 'publication_id',
          primary_key: 'publication_id'
end