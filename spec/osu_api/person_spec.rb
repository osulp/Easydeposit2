# frozen_string_literal: true

RSpec.describe OsuApi::Person do
  let(:person) { described_class.new(attributes) }
  let(:attributes) do
    {
      'firstName' => 'Bob',
      'lastName' => 'Ross',
      'primaryAffiliation' => 'Employee',
      'emailAddress' => 'bob@ross'
    }
  end

  it 'has attributes' do
    expect(person.first_name).to eq(attributes['firstName'])
    expect(person.last_name).to eq(attributes['lastName'])
    expect(person.primary_affiliation).to eq(attributes['primaryAffiliation'])
    expect(person.email_address).to eq(attributes['emailAddress'])
  end
end
