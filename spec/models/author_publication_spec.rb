# frozen_string_literal: true

RSpec.describe AuthorPublication, type: :model do
  let(:author_publication) { create(:author_publication_with_publication) }
  it 'has a publication' do
    expect(author_publication.publication).to be_a(Publication)
  end
end
