# frozen_string_literal: true

describe WebOfScience::FetchAuthorsEmailsWos do
  let(:publication) { create(:publication) }
  it 'fetches authors emails from the Web Of Science full record' do
    expect(described_class.fetch_from_api(publication).first).to eq 'Srembaa@onid.orst.edu'
  end
end
