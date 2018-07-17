# frozen_string_literal: true

##
# Author details related to each publication
class AuthorPublication < ActiveRecord::Base
  belongs_to :publication, inverse_of: :author_publications
end
