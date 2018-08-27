# frozen_string_literal: true

RSpec.describe FetchWosContentJob do
  let(:default_job_options) { { retry: 0 } }
  let(:job) { FetchWosContentJob.new }
  let(:user) { create(:user) }
  let(:publication) { create(:publication) }
  let(:fetch_return) { { emails: [['john.smith@oregonstate.edu'], ['mary.rose@gmail.com']], abstract: 'abstract' } }
  it 'has default job options' do
    expect(described_class.job_options(nil)).to eq default_job_options
  end

  it 'processes a successful job' do
    allow(job).to receive(:fetch_wos_content) { fetch_return }
    allow(job).to receive(:create_or_update_publication_emails).with(fetch_return[:emails], publication) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.events.count).to eq 1
    expect(user.events.first.status).to eq 'completed'
    expect(user.events.first.name).to eq 'Fetch publication content from Web of Science'
    expect(user.events.first.message).to eq 'Found 2 author emails and abstract in Web of Science full records.'
    expect(publication[:pub_at]).to be_falsey
  end
  it 'processes an job with no authors found' do
    allow(job).to receive(:fetch_wos_content) { { emails: [], abstract: '' } }
    allow(job).to receive(:create_or_update_publication_emails).with([], publication) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.events.count).to eq 1
    expect(user.events.first.status).to eq 'completed'
    expect(user.events.first.name).to eq 'Fetch publication content from Web of Science'
    expect(user.events.first.message).to eq 'Found 0 author emails and abstract in Web of Science full records.'
    expect(publication[:pub_at]).to be_falsey
  end
  it 'processes an error' do
    allow(job).to receive(:fetch_wos_content) { { emails: [], abstract: '' } }
    allow(job).to receive(:create_or_update_publication_emails).with([], publication) { raise 'Boom' }
    job.perform(publication: publication, current_user: user)
    expect(user.events.count).to eq 1
    expect(user.events.first.status).to eq 'error'
    expect(user.events.first.name).to eq 'Fetch publication content from Web of Science'
    expect(user.events.first.message).to eq 'FetchWosContentJob.perform : Boom'
    expect(publication[:pub_at]).to be_falsey
  end
end
