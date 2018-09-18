FactoryBot.define do
  factory :author_publication do
    email 'test@test.com'
    name 'Some User'
    primary_affiliation 'Employee'
    claim_link 'a test link'
  end

  factory :author_publication_with_references, class: AuthorPublication do
    email 'test@test.com'
    name 'Some User'
    primary_affiliation 'Employee'
    claim_link 'a test link'
    publication
    user
  end
end
