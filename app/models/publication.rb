# frozen_string_literal: true

##
# A publication, the central model of the application
class Publication < ActiveRecord::Base
  include AASM

  has_paper_trail on: [:destroy]

  scope :by_wos_uid, lambda { |uid|
    joins(:web_of_science_source_record)
      .where('web_of_science_source_records.uid = ?', uid)
  }

  has_one :web_of_science_source_record, autosave: true, dependent: :destroy
  has_many_attached :publication_files
  has_many :events, inverse_of: :publication, dependent: :destroy
  has_and_belongs_to_many :users
  has_and_belongs_to_many :cas_users
  has_many :author_publications, inverse_of: :publication, dependent: :destroy

  serialize :pub_hash, Hash

  after_save :update_pub_hash
  after_create :fetch_authors!

  def delete!
    self.deleted = true
    save
  end

  def deleted?
    deleted
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

  ##
  # Find and update or create a new AuthorPublication for an array of people
  # supplied. The unique key is the email address and publication.
  #
  # Extended for claiming publication without user login:
  # - create a new user record with email fetch by OSU directory API
  # - create a hash_id based on author email and assign it to AuthorPublication
  # @param Array<Hash<AuthorPublication>> people - an array of people attributes
  def add_author_emails(people)
    people.each do |person|
      user = User.find_or_initialize_by(email: person[:email])
      user.save(validate: false) if user.new_record?
      record = AuthorPublication.find_or_initialize_by(email: person[:email], publication: self)
      record.attributes = person
      record.user = user
      record.claim_link ||= Digest::SHA2.hexdigest("#{to_param}#{person[:email]}")
      record.save
    end
  end

  aasm do
    state :initialized, initial: true
    state :fetching_authors
    state :recruiting_authors
    state :awaiting_claim
    state :awaiting_attachments
    state :publication_exists
    state :publishing_failed
    state :published

    # disable fetching email from WoS
    event :fetch_authors do
      after do
        FetchAuthorsDirectoryApiJob.perform_later(publication: self)
        # FetchWosContentJob.perform_later(publication: self)
      end
      transitions from: :initialized, to: :fetching_authors
    end
    event :recruit_authors do
      after do
        EmailArticleRecruitJob.perform_later(publication: self)
      end
      transitions from: :fetching_authors, to: :recruiting_authors, guard: :completed_fetching_authors?
    end
    event :await_claim do
      transitions from: :recruiting_authors, to: :awaiting_claim
    end
    event :await_attachments do
      transitions from: :awaiting_claim, to: :awaiting_attachments
    end
    event :publish_exists do
      after do
        update(pub_at: Time.now)
      end
      transitions from: [:awaiting_attachments, :publishing_failed], to: :publication_exists
    end
    event :publish_failed do
      transitions from: :awaiting_attachments, to: :publishing_failed
    end
    event :publish do
      after do
        update(pub_at: Time.now)
      end
      transitions from: [:awaiting_attachments, :publishing_failed, :publication_exists], to: :published, guard: :ready_to_publish?
    end
  end

  private

  def update_pub_hash
    return unless web_of_science_source_record
    update_column(:pub_hash, web_of_science_source_record.record.to_h)
  end

  def duplicate_files_validation(duplicates)
    logger.error "Duplicate uploads found: #{duplicates}, returning error."
    errors.add :base,
               "Cannot upload duplicate files, found: #{duplicates.join(', ')}"
  end

  def completed_fetching_authors?
    events.reload.where(name: [Event::FETCH_AUTHORS_DIRECTORY_API[:name], Event::FETCH_WOS_CONTENT[:name]], status: Event::COMPLETED[:name]).count >= 2
  end
end
