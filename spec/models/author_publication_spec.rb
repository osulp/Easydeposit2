# frozen_string_literal: true

RSpec.describe AuthorPublication, type: :model do
  let(:author_publication) { create(:author_publication_with_publication) }
  it 'has a publication' do
    expect(author_publication.publication).to be_a(Publication)
  end

  subject do
    AuthorPublication.new(email: 'test@test.edu', claim_link: 'test_claim_link') { |a| a.save!(validate: false) }
  end
  it 'has an email' do
    expect(subject.email).to eq 'test@test.edu'
  end
  it 'has a claim_url' do
    expect(subject.claim_link).to eq 'test_claim_link'
  end
end
