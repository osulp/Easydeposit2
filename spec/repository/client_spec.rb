# frozen_string_literal: true

ENV['REPOSITORY_ADMIN_SET_URL'] = 'bogus'
ENV['REPOSITORY_AUTHENTICATION_TOKEN'] = 'bogus'
ENV['REPOSITORY_AUTHENTICATION_USERNAME'] = 'bogus'
ENV['REPOSITORY_SEARCH_URL'] = '/catalog?q="{value}"&{property}="{value}"'
ENV['REPOSITORY_UPLOAD_URL'] = 'bogus'
ENV['REPOSITORY_URL'] = 'bogus'
ENV['REPOSITORY_WORKFLOW_URL'] = '/workflow/{work_id}.json'
ENV['HTTP_AUTH_HEADER'] = 'bogus'

RSpec.describe Repository::Client do
  let(:client) { described_class.new }
  let(:connection) { double('Faraday', post: response, put: response, get: response) }
  let(:response) { double('HTTPReponse', body: response_body, reason_phrase: reason_phrase, success?: success, finished?: finished) }
  let(:response_body) { '{}' }
  let(:reason_phrase) { 'Created.' }
  let(:success) { true }
  let(:finished) { true }

  before(:each) do
    allow(client).to receive(:connection) { connection }
    allow(client).to receive(:multipart_connection) { connection }
  end

  it 'should initialize' do
    expect(client.token).to eq ENV['REPOSITORY_AUTHENTICATION_TOKEN']
    expect(client.username).to eq ENV['REPOSITORY_AUTHENTICATION_USERNAME']
    expect(client.url).to eq ENV['REPOSITORY_URL']
  end

  context '#publish' do
    let(:response_body) { '{ "id": "abc123", "title": ["abctitle"] }' }
    let(:publish_object) { { 'id' => 'abc123', 'title' => ['abctitle'] } }
    let(:publish_result) { { response: response, work: { 'id' => 'abc123', 'title' => ['abctitle'] } } }
    it 'publishes a work' do
      expect(client.publish(publish_object, '/concern/article')).to eq publish_result
    end
    context 'when fails' do
      let(:success) { false }
      let(:reason_phrase) { 'broke!' }
      it 'raises an error' do
        expect { client.publish(publish_object, '/concern/article') }.to raise_error 'broke!'
      end
    end
  end

  context '#set_workflow' do
    let(:response_body) { '{ "id": "abc123", "name": "abctitle" }' }
    let(:workflow_object) { { 'id' => 'abc123', 'name' => 'abctitle' } }
    it 'sets the workflow for a work' do
      expect(client.set_workflow(workflow_object, 'Approve', 'Comment')).to be_truthy
    end
  end

  context '#fetch_all_admin_sets' do
    let(:response_body) { '{ "id": "abc123", "name": ["admin_set1","admin_set2"] }' }
    let(:admin_sets_object) { { 'id' => 'abc123', 'name' => ['admin_set1','admin_set2'] } }
    it 'gets all admin sets from the server' do
      expect(client.fetch_all_admin_sets).to eq admin_sets_object
      expect(client.admin_sets).to eq admin_sets_object
    end
    context 'when fails' do
      let(:success) { false }
      let(:reason_phrase) { 'broke!' }
      it 'raises an error' do
        expect { client.fetch_all_admin_sets }.to raise_error 'broke!'
      end
    end
  end

  context '#search' do
    let(:response_body) { '{ "response": { "docs": [{ "id": "abc123", "title": "abctitle" }] } }' }
    let(:search_object) { [{ 'id' => 'abc123', 'title' => 'abctitle' }] }
    it 'finds a work' do
      expect(client.search('web_of_science_uid', 'WOS:1234567890')).to eq search_object
    end
    context 'when fails' do
      let(:success) { false }
      let(:reason_phrase) { 'broke!' }
      it 'raises an error' do
        expect { client.search('web_of_science_uid', 'WOS:1234567890') }.to raise_error 'broke!'
      end
    end
  end

  context '#upload_file' do
    let(:response_body) { '{ "files": [{ "id": 1 }] }' }
    let(:upload_object) { { 'files' => [{ 'id' => 1 }] } }
    it 'finds a work' do
      expect(client.upload_file(__FILE__, 'text/plain')).to eq upload_object
    end
    context 'when fails' do
      let(:success) { false }
      let(:reason_phrase) { 'broke!' }
      it 'raises an error' do
        expect { client.upload_file(__FILE__, 'text/plain') }.to raise_error 'broke!'
      end
    end
  end
end
