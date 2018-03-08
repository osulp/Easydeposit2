class Author < ActiveRecord::Base
  
    # Provide consistent API for Author and AuthorIdentity
    alias_attribute :first_name, :preferred_first_name
    alias_attribute :middle_name, :preferred_middle_name
    alias_attribute :last_name, :preferred_last_name
  
    # Provide consistent API for Author and AuthorIdentity
    # The default institution is set in
    # Settings.HARVESTER.INSTITUTION.name
    # @return [String] institution
    def institution
      Settings.HARVESTER.INSTITUTION.name
    end
  
    # TODO: CAP could provide dates for Stanford affiliation
    # Provide consistent API for Author and AuthorIdentity
    # @return [nil]
    def start_date
      nil
    end
  
    # TODO: CAP could provide dates for Stanford affiliation
    # Provide consistent API for Author and AuthorIdentity
    # @return [nil]
    def end_date
      nil
    end
  
    has_many :publications

  end