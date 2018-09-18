class AddClaimLinkToAuthorPublications < ActiveRecord::Migration[5.2]
  def change
    add_column :author_publications, :claim_link, :string
  end
end

