RSpec.describe User, type: :model do
  subject do
    User.new(email: 'test@example.com') { |u| u.save!(validate: false)}
  end

  it 'has a username' do
    expect(subject.username).to eq 'test@example.com'
  end
end
