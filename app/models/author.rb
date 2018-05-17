class Author < ActiveRecord::Base
  has_paper_trail on: [:destroy]

  has_many :contributions, dependent: :destroy
  has_many :publications, through: :contributions

  # The default institution is set in Settings.HARVESTER.INSTITUTION.name
  # @return [String] institution
  def institution
    Settings.HARVESTER.INSTITUTION.name
  end

  # @param [Publication]
  # @return [Contribution]
  def assign_pub(pub)
    raise 'Author must be saved before association' unless persisted?
    pub.contributions.find_or_create_by!(author_id: id) do |contrib|
      contrib.assign_attributes(
          cap_profile_id: cap_profile_id,
          featured: false, status: 'new', visibility: 'private'
      )
      pub.pubhash_needs_update! # Add to pub_hash[:authorship]
      pub.save! # contrib.save! not needed
    end
  end

  private

end