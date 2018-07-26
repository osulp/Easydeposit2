# frozen_string_literal: true

describe WebOfScience::FetchAuthorsEmailsWos do
  let(:source) { File.read(Rails.root.join('spec/factories/web_of_science_full_record_body.htm')) }
  it 'fetches authors emails from the Web Of Science full record' do
    expect(source.scan(/mailto:(.*?)\"/).first).to eq ["Srembaa@onid.orst.edu"]
  end
end
