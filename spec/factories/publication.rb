FactoryBot.define do
  factory :publication do
    title 'Publication Title'
    web_of_science_source_record

    factory :publication_with_authors do
      transient do
        author_count 3
      end
      after(:create) do |p, evaluator|
        create_list(:author_publications, evaluator.author_count, publication: p)
      end
    end
  end
end
