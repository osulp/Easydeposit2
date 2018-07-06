class Publication < ActiveRecord::Base
  has_paper_trail on: [:destroy]

  scope :by_wos_uid, ->(uid) { joins(:web_of_science_source_record).where('web_of_science_source_records.uid = ?', uid ) }

  has_one :web_of_science_source_record, autosave: true, dependent: :destroy
  has_many_attached :publication_files
  has_many :jobs, inverse_of: :publication, dependent: :destroy

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

  # Vanity ID for use in the simple_form_for, referring to the publication by its related WOS Uid
  def to_param
    web_of_science_source_record[:uid]
  end

  def has_unique_publication_files(params)
    params_files = params.map {|p| p.original_filename}
    attached_files = publication_files.map {|p| p.filename.to_s }
    duplicates = params_files.select { |f| attached_files.count(f) > 0}.uniq
    logger.error "Duplicate uploads found: #{duplicates}, returning error."
    errors.add(:base, "Cannot have duplicate files uploaded, file already attached: #{duplicates.join(', ')}") unless duplicates.blank?
    duplicates.blank?
  end
end
