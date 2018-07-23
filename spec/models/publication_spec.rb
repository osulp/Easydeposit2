# frozen_string_literal: true

RSpec.describe Publication, type: :model do
  let(:publication) { create(:publication) }
  let(:person) do
    {
      email: 'bob@ross.com',
      name: 'Ross, Bob',
      primary_affiliation: 'employee'
    }
  end
  let(:attached_files_params) { [double('Bogus Params', original_filename: 'my_awesome.pdf')] }
  it 'has pub_hash' do
    expect(publication.pub_hash).to be_truthy
  end
  it 'can use the WOS UID for the url param' do
    expect(publication.to_param).to eq(publication.web_of_science_source_record[:uid])
  end
  it 'is not deleted' do
    expect(publication.deleted?).to be_falsey
  end
  it 'is not published' do
    expect(publication.published?).to be_falsey
  end
  it 'is not ready to be published' do
    expect(publication.ready_to_publish?).to be_falsey
  end
  it 'adds author publication emails' do
    expect(publication.add_author_emails([person])).to be_truthy
  end
  it 'checks that there are no duplicate publication file names' do
    expect(publication.unique_publication_files?(attached_files_params)).to be_truthy
  end
  it 'errors with there are duplicate publication files names' do
    allow(publication).to receive(:publication_files) { [double('Bogus ActiveStorage File', filename: 'my_awesome.pdf')] }
    expect(publication.unique_publication_files?(attached_files_params)).to be_falsey
  end
  it 'finds by WOS UID' do
    p = FactoryBot.create(:publication)
    expect(described_class.by_wos_uid('WOS:1234567890').first).to eq p
  end
  context 'can delete itself' do
    before do
      create(:publication)
    end
    it 'deletes itself' do
      expect(publication.delete!).to be_truthy
    end
  end
end
