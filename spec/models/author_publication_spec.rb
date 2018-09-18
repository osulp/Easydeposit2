# frozen_string_literal: true

RSpec.describe AuthorPublication, type: :model do
  let(:author_publication) { create(:author_publication_with_publication) }
  it 'has a publication' do
    expect(author_publication.publication).to be_a(Publication)
  end
  it 'has an email' do
    expect(author_publication.email).to eq 'test@test.com'
  end
  it 'has a claim_link' do
    expect(author_publication.claim_link).to eq 'a test link'
  end
end
