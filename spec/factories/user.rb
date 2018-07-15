FactoryBot.define do
  factory :user do
    email 'bob@ross.com'
    password 'blahblahblah'
    username 'Bob Ross'
    admin false
  end

  # This will use the User class (Admin would have been guessed)
  factory :admin, class: User do
    username 'Bob Ross'
    password 'blahblahblah'
    email 'bob@ross.com'
    admin true
  end
end
