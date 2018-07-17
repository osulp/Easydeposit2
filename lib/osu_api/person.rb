# frozen_string_literal: true

module OsuApi
  ##
  # Person object from the OSU Directory API
  class Person
    attr_accessor :first_name, :last_name, :primary_affiliation, :email_address
    def initialize(attributes)
      @first_name = attributes['firstName']
      @last_name = attributes['lastName']
      @primary_affiliation = attributes['primaryAffiliation']
      @email_address = attributes['emailAddress']
    end
  end
end
