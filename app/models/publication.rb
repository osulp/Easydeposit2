# frozen_string_literal: true

##
# A publication, the central model of the application
class Publication < ActiveRecord::Base
  has_paper_trail on: [:destroy]

  scope :by_wos_uid, lambda { |uid|
    joins(:web_of_science_source_record)
      .where('web_of_science_source_records.uid = ?', uid)
  }

  has_one :web_of_science_source_record, autosave: true, dependent: :destroy
  has_many_attached :publication_files
  has_many :jobs, inverse_of: :publication, dependent: :destroy
  has_and_belongs_to_many :users
  has_and_belongs_to_many :cas_users
  has_many :author_publications, inverse_of: :publication

  serialize :pub_hash, Hash

  def delete!
    self.deleted = true
    save
  end

  def deleted?
    deleted
  end

  def issn
    pub_hash[:issn]
  end

  def pages
    pub_hash[:pages]
  end

  def publication_type
    pub_hash[:type]
  end

  # @note obscures ActiveRecord field/attribute getter for title
  def title
    pub_hash[:title]
  end

  # @note obscures ActiveRecord field/attribute getter for year
  def year
    pub_hash[:year]
  end

  # Vanity ID for use in the simple_form_for,
  # referring to the publication by its related WOS Uid
  def to_param
    web_of_science_source_record[:uid]
  end

  def unique_publication_files?(params)
    attached_files = publication_files.map { |p| p.filename.to_s }
    duplicates = params.map(&:original_filename)
                       .select { |f| attached_files.count(f).positive? }
                       .uniq
    duplicate_files_validation(duplicates) unless duplicates.blank?
    duplicates.blank?
  end

  def published?
    !pub_at.blank?
  end

  def ready_to_publish?
    publication_files.count.positive? && pub_at.blank?
  end

  def duplicate_files_validation(duplicates)
    logger.error "Duplicate uploads found: #{duplicates}, returning error."
    errors.add :base,
               "Cannot upload duplicate files, found: #{duplicates.join(', ')}"
  end

  ##
  # Find and update or create a new AuthorPublication for an array of people
  # supplied. The unique key is the email address and publication.
  #
  # @param Array<Hash<AuthorPublication>> people - an array of people attributes
  def add_author_emails(people)
    people.each do |person|
      record = AuthorPublication.find_or_initialize_by(email: person[:email], publication: self)
      record.attributes = person
      record.save
    end
  end
end
