# frozen_string_literal: true

RSpec.describe FetchAuthorsEmailsWosJob do
  let(:default_job_options) { { retry: 0 } }
  let(:job) { FetchAuthorsEmailsWosJob.new }
  let(:user) { create(:user) }
  let(:publication) { create(:publication) }
  let(:fetch_email_return) { [['john.smith@oregonstate.edu'], ['mary.rose@gmail.com']] }
  it 'has default job options' do
    expect(described_class.job_options(nil)).to eq default_job_options
  end

  it 'processes a successful job' do
    allow(job).to receive(:fetch_authors_emails) { fetch_email_return }
    allow(job).to receive(:create_or_update_publication_emails).with(fetch_email_return, publication) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.jobs.count).to eq 1
    expect(user.jobs.first.status).to eq 'completed'
    expect(user.jobs.first.name).to eq 'Fetch Authors Emails from Web of Science'
    expect(user.jobs.first.message).to eq 'Found 2 author emails in Web of Science full records.'
    expect(publication[:pub_at]).to be_falsey
  end
  it 'processes an job with no authors found' do
    allow(job).to receive(:fetch_authors_emails) { [] }
    allow(job).to receive(:create_or_update_publication_emails).with([], publication) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.jobs.count).to eq 1
    expect(user.jobs.first.status).to eq 'completed'
    expect(user.jobs.first.name).to eq 'Fetch Authors Emails from Web of Science'
    expect(user.jobs.first.message).to eq 'Found 0 author emails in Web of Science full records.'
    expect(publication[:pub_at]).to be_falsey
  end
  it 'processes an error' do
    allow(job).to receive(:fetch_authors_emails) { [] }
    allow(job).to receive(:create_or_update_publication_emails).with([], publication) { raise 'Boom' }
    job.perform(publication: publication, current_user: user)
    expect(user.jobs.count).to eq 1
    expect(user.jobs.first.status).to eq 'error'
    expect(user.jobs.first.name).to eq 'Fetch Authors Emails from Web of Science'
    expect(user.jobs.first.message).to eq 'FetchAuthorsEmailsWosJob.perform : Boom'
    expect(publication[:pub_at]).to be_falsey
  end
end
