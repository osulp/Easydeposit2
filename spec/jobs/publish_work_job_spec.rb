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
             admin_sets: { 'admin_sets' => [{ 'title' => ['article'], 'id' => '123456' }] },
             upload_file: { 'files' => ['id' => 1] },
             publish: { work: publication, response: double('HTTPResponse', headers: { location: '/concern/articles/123' }) })
    end
    allow(publication).to receive(:publication_files) { [publication_file] }
    allow(job).to receive(:email_published_notification) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.events.last.status).to eq 'completed'
    expect(user.events.last.name).to eq 'Publish Work'
    expect(user.events.last.message).to start_with 'Published to the repository at'
    expect(publication[:pub_url]).to eq 'http://hyrax.server/concern/articles/123'
  end

  it 'processes a publication that had already been published job' do
    allow(job).to receive(:published_works) { [{ blah: 'blah' }] }
    allow(job).to receive(:email_published_notification) { true }
    job.perform(publication: publication, current_user: user)
    expect(user.events.last.status).to eq 'warn'
    expect(user.events.last.name).to eq 'Publish Work'
    expect(user.events.last.message).to start_with 'Publication already exists in the repository.'
    expect(publication[:pub_at]).to be_truthy
  end

  it 'processes an error' do
    allow(job).to receive(:published_new?) { raise 'Boom' }
    job.perform(publication: publication, current_user: user)
    expect(user.events.last.status).to eq 'error'
    expect(user.events.last.name).to eq 'Publish Work'
    expect(user.events.last.message).to eq 'PublishWorkJob.perform : Boom'
    expect(publication[:pub_at]).to be_falsey
  end
end
