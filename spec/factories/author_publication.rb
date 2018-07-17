FactoryBot.define do
  factory :author_publication do
    email 'test@test.com'
    name 'Some User'
    primary_affiliation 'Employee'
  end

  factory :author_publication_with_publication, class: AuthorPublication do
    email 'test@test.com'
    name 'Some User'
    primary_affiliation 'Employee'
    publication
  end
end
