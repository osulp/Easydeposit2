FactoryBot.define do
  factory :publication do
    title 'Publication Title'
  end

  factory :publication_with_wossr, class: Publication do
    title 'Publication with Web Of Science Source Record'
    web_of_science_source_record
  end
end
