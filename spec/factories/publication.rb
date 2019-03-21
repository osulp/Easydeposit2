FactoryBot.define do
  factory :publication do
    aasm_state { "awaiting_attachments" }
    web_of_science_source_record

    after(:build) do |p|
      p.class.skip_callback(:create, :after, :fetch_authors!, raise: false)
    end

    factory :publication_with_authors do
      transient do
        author_count { 3 }
      end
      after(:build) do |p|
        p.class.skip_callback(:create, :after, :fetch_authors!, raise: false)
      end
      after(:create) do |p, evaluator|
        create_list(:author_publications, evaluator.author_count, publication: p)
      end
    end
  end
end
