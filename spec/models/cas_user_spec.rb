RSpec.describe CasUser, type: :model do
  subject do
    CasUser.new(cas_extra_attributes: { email: 'test@example.com', fullname: 'test person'}, username: 'test') { |u| u.save!(validate: false)}
  end

  it 'has a username' do
    expect(subject.username).to eq 'test'
  end
  it 'has a email' do
    expect(subject.email).to eq 'test@example.com'
  end
  it 'has a display name' do
    expect(subject.display_name).to eq 'test person'
  end
end
