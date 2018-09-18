# frozen_string_literal: true

RSpec.describe AuthorPublication, type: :model do
  let(:author_publication) { create(:author_publication_with_references) }
  it 'has a publication' do
    expect(author_publication.publication).to be_a(Publication)
  end
  it 'has an user' do
    expect(author_publication.user).to be_a(User)
  end
end
