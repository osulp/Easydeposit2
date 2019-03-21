FactoryBot.define do
  factory :web_of_science_source_record do
    uid { "WOS:1234567890" }
    active { true }
    database { "WOS" }
    source_data { File.read(Rails.root.join('spec/factories/web_of_science_source_record.xml')) }
    source_fingerprint { "123" }
  end
end
