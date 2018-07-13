RSpec.describe ApplicationHelper, type: :helper do
  describe '#full_title' do
    let(:page_title) { 'Bob Ross' }
    let(:base_title) { 'EasyDeposit2: OSU Publication Database'}

    it 'returns just a base title' do
      expect(helper.full_title('')).to eq base_title
    end

    it 'returns a page and base title' do
      expect(helper.full_title(page_title)).to eq "#{base_title} | #{page_title}"
    end
  end
end
