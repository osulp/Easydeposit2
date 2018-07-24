# frozen_string_literal: true

RSpec.describe PublishWorkJob do
  let(:default_job_options) { { retry: 0 } }
  let(:job) { PublishWorkJob.new }
  let(:user) { create(:user) }
  let(:publication) { create(:publication) }
  it 'has default job options' do
    expect(described_class.job_options(nil)).to eq default_job_options
  end

  it 'processes a successful job' do
    allow(job).to receive(:publication_exists?).with(publication) { false }
    allow(job).to receive(:publish!).with(publication) { true }
    allow(job).to receive(:email_published_notification).with(user, publication) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.jobs.count).to eq 1
    expect(user.jobs.first.status).to eq 'completed'
    expect(user.jobs.first.name).to eq 'Publish Work'
    expect(user.jobs.first.message).to start_with 'Published to the repository at'
    expect(publication[:pub_at]).to be_truthy
  end

  it 'processes a publication that had already been published job' do
    allow(job).to receive(:publication_exists?).with(publication) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.jobs.count).to eq 1
    expect(user.jobs.first.status).to eq 'warn'
    expect(user.jobs.first.name).to eq 'Publish Work'
    expect(user.jobs.first.message).to start_with 'Publication already exists in the repository. Skipped publishing at'
    expect(publication[:pub_at]).to be_falsey
  end

  it 'processes an error' do
    allow(job).to receive(:published?) { raise 'Boom' }
    job.perform(publication: publication, current_user: user)
    expect(user.jobs.count).to eq 1
    expect(user.jobs.first.status).to eq 'error'
    expect(user.jobs.first.name).to eq 'Publish Work'
    expect(user.jobs.first.message).to eq 'PublishWorkJob.perform : Boom'
    expect(publication[:pub_at]).to be_falsey
  end
end
