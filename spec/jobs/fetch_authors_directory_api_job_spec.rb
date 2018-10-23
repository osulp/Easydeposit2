# frozen_string_literal: true

RSpec.describe FetchAuthorsDirectoryApiJob do
  let(:default_job_options) { { retry: 0 } }
  let(:job) { FetchAuthorsDirectoryApiJob.new }
  let(:user) { create(:user) }
  let(:publication) { create(:publication) }
  let(:api_return) do
    [
      {
        email_address: 'bob@ross.com',
        name: 'Ross, Bob',
        primary_affiliation: 'employee'
      }
    ]
  end
  it 'has default job options' do
    expect(described_class.job_options(nil)).to eq default_job_options
  end

  it 'processes a successful job' do
    allow(job).to receive(:query_api) { api_return }
    allow(job).to receive(:process_found_authors).with(api_return, publication) { true }
    allow(job).to receive(:process_system_authors) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.events.count).to eq 1
    expect(user.events.first.status).to eq 'completed'
    expect(user.events.first.name).to eq 'Fetch Authors from Directory API'
    expect(user.events.first.message).to eq 'Found 1 person in Directory API.'
    expect(publication[:pub_at]).to be_falsey
  end
  it 'processes an job with no authors found' do
    allow(job).to receive(:query_api) { [] }
    allow(job).to receive(:process_found_authors).with([], publication) { true }
    allow(job).to receive(:process_system_authors) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.events.count).to eq 1
    expect(user.events.first.status).to eq 'completed'
    expect(user.events.first.name).to eq 'Fetch Authors from Directory API'
    expect(user.events.first.message).to eq 'Found no authors for this publication in the Directory API'
    expect(publication[:pub_at]).to be_falsey
  end
end
