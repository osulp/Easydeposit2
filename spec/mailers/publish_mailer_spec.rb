RSpec.describe PublishMailer, type: :mailer do
  describe '#published_email' do
    let(:mail) { described_class.with(params).published_email }
    let(:user) { create(:user) }
    let(:publication) { create(:publication) }
    let(:params) { { user: user, publication: publication, email: user.email } }
    it 'sends the email' do
      expect(mail.subject).to eq("#{publication.web_of_science_source_record[:uid]} work published to repository.")
      expect(mail.to).to eq [user.email]
    end
  end
end
