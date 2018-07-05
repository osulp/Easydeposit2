class Publication < ActiveRecord::Base
  has_paper_trail on: [:destroy]

  scope :by_wos_uid, ->(uid) { joins(:web_of_science_source_record).where('web_of_science_source_records.uid = ?', uid ) }

  has_one :web_of_science_source_record, autosave: true

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
end
