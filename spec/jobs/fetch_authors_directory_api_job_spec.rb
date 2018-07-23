RSpec.describe FetchAuthorsDirectoryApiJob do
  let(:default_job_options) {
    { retry: 0 }
  }
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
    allow(job).to receive(:process_found_authors).with(api_return) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.jobs.count).to eq 1
    expect(user.jobs.first.status).to eq 'completed'
    expect(user.jobs.first.name).to eq 'Fetch Authors from Directory API'
    expect(user.jobs.first.message).to eq 'Found 1 person in Directory API.'
    expect(publication[:pub_at]).to be_falsey
  end
  it 'processes an job with no authors found' do
    allow(job).to receive(:query_api) { [] }
    allow(job).to receive(:process_found_authors).with([]) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.jobs.count).to eq 1
    expect(user.jobs.first.status).to eq 'completed'
    expect(user.jobs.first.name).to eq 'Fetch Authors from Directory API'
    expect(user.jobs.first.message).to eq 'Found 0 people in Directory API.'
    expect(publication[:pub_at]).to be_falsey
  end
  it 'processes an error' do
    allow(job).to receive(:query_api) { [] }
    allow(job).to receive(:process_found_authors).with([]) { raise 'Boom' }
    job.perform(publication: publication, current_user: user)
    expect(user.jobs.count).to eq 1
    expect(user.jobs.first.status).to eq 'error'
    expect(user.jobs.first.name).to eq 'Fetch Authors from Directory API'
    expect(user.jobs.first.message).to eq 'FetchAuthorsDirectoryApiJob.perform : Boom'
    expect(publication[:pub_at]).to be_falsey
  end
end
