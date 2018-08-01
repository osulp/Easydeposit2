RSpec.describe ArticleRecruitMailer, type: :mailer do
  describe '#published_email' do
    let(:mail) { described_class.with(params).published_email}
    let(:user) { create(:user) }
    let(:publication) { create(:publication) }
    let(:params) { { user: user, publication: publication, emails: [user.email] } }
    it 'sends the email' do
      expect(mail.subject).to eq("Oregon State University Library invites you to deposit your recent publication: #{publication.web_of_science_source_record[:uid]}")
      expect(mail.to).to eq [user.email]
    end
  end
end