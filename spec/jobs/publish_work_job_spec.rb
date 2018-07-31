# frozen_string_literal: true

RSpec.describe PublishWorkJob do
  let(:default_job_options) { { retry: 0 } }
  let(:job) { PublishWorkJob.new }
  let(:user) { create(:user) }
  let(:publication) { create(:publication) }
  let(:publication_file) { double('PublicationFile', key: 'key', filename: 'filename', download: 'blahblahblah', content_type: 'text/plain') }
  it 'has default job options' do
    expect(described_class.job_options(nil)).to eq default_job_options
  end

  it 'processes a successful job' do
    allow(job).to receive(:repository_client) do
      double('Repository::Client',
             url: 'http://hyrax.server',
             search: [],
             admin_sets: { 'admin_sets' => [{ 'title' => ['self deposit'], 'id' => '123456' }] },
             upload_file: { 'files' => ['id' => 1] },
             publish: { work: publication, response: double('HTTPResponse', headers: { location: '/concern/articles/123' }) })
    end
    allow(publication).to receive(:publication_files) { [publication_file] }
    allow(job).to receive(:email_published_notification) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.jobs.count).to eq 1
    expect(user.jobs.first.status).to eq 'completed'
    expect(user.jobs.first.name).to eq 'Publish Work'
    expect(user.jobs.first.message).to start_with 'Published to the repository at'
    expect(publication[:pub_at]).to be_truthy
    expect(publication[:pub_url]).to eq 'http://hyrax.server/concern/articles/123'
  end

  it 'processes a publication that had already been published job' do
    allow(job).to receive(:published_works) { [{ blah: 'blah' }] }
    job.perform(publication: publication, current_user: user)
    expect(user.jobs.count).to eq 1
    expect(user.jobs.first.status).to eq 'warn'
    expect(user.jobs.first.name).to eq 'Publish Work'
    expect(user.jobs.first.message).to start_with 'Publication already exists in the repository. Found 1 on server with WOS:1234567890. Skipped publishing at'
    expect(publication[:pub_at]).to be_falsey
  end

  it 'processes an error' do
    allow(job).to receive(:published_new?) { raise 'Boom' }
    job.perform(publication: publication, current_user: user)
    expect(user.jobs.count).to eq 1
    expect(user.jobs.first.status).to eq 'error'
    expect(user.jobs.first.name).to eq 'Publish Work'
    expect(user.jobs.first.message).to eq 'PublishWorkJob.perform : Boom'
    expect(publication[:pub_at]).to be_falsey
  end
end
