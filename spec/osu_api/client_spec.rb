# frozen_string_literal: true

ENV['OSU_API_URL'] = 'https://server'
ENV['OSU_API_OAUTH2_TOKEN'] = '/oauth'
ENV['OSU_API_DIRECTORY_SEARCH'] = '/directory'
ENV['OSU_API_CONSUMER_KEY'] = 'key'
ENV['OSU_API_CONSUMER_SECRET'] = 'secret'

RSpec.describe OsuApi::Client do
  let(:client) { described_class.new }
  let(:directory_response) do
    {
      'links' => nil,
      'data' => [
        {
          'id' => 123_456,
          'type' => 'directory',
          'attributes' => {
            'firstName' => 'Bob',
            'lastName' => 'Ross',
            'fullName' => 'Ross, Bob',
            'primaryAffiliation' => 'Employee',
            'jobTitle' => 'Assistant Professor',
            'department' => 'Microart (Science)',
            'departmentMailingAddress' => 'Microart\nOregon State University',
            'homePhoneNumber' => '1 555 555 5555',
            'homeAddress' => '123 Main\nCorvallis, OR 97330',
            'officePhoneNumber' => nil,
            'officeAddress' => nil,
            'faxNumber' => nil,
            'emailAddress' => 'bob@ross',
            'username' => 'rossbob',
            'alternatePhoneNumber' => nil,
            'osuuid' => 12_345_678_901
          },
          'links' => {
            'self' => 'https://api.oregonstate.edu/v1/directory/123456'
          }
        }
      ]
    }
  end

  let(:one_person) do
    OsuApi::Person.new(directory_response['data'][0]['attributes'])
  end

  it 'queries the directory for a person' do
    allow(client).to receive(:get) { directory_response }
    result = client.directory_query('Ross, Bob')
    expect(result).to be_a Array
    expect(result.first).to be_a OsuApi::Person
    expect(result.first.email_address).to eq one_person.email_address
  end
end
