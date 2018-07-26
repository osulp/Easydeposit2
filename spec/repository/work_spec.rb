# frozen_string_literal: true

RSpec.describe Repository::Work do
  let(:work) { described_class.new(args) }
  let(:created_work) { { id: 'a1b2c3d4' } }
  let(:advanced_workflow) { { id: 'a1b2c3d4', action: 'Approve', comment: 'Published by ED2' } }
  let(:client) { double('Repository::Client') }
  let(:admin_sets) { { 'admin_sets' => [{ 'id' => 'blah1', 'title' => ['Default Admin Set'] }] } }
  let(:uploaded_file) { { 'files' => [{ 'id' => 1 }] } }
  let(:args) do
    {
      client: client,
      data: {
        title: ['Title'],
        web_of_science_uid: 'WOS:8675309'
      },
      files: [
        {
          path: __FILE__,
          content_type: 'application/pdf'
        }
      ],
      work_type: 'article',
      admin_set_title: 'Default Admin Set'
    }
  end

  it 'can publish the work with supplied files' do
    allow(client).to receive(:admin_sets) { admin_sets }
    allow(client).to receive(:upload_file) { uploaded_file }
    allow(client).to receive(:publish) { created_work }
    allow(client).to receive(:set_workflow) { advanced_workflow }
    expect(work.publish).to eq advanced_workflow
  end

  it 'will not publish the work without supplied files' do
    allow(client).to receive(:admin_sets) { admin_sets }
    allow(client).to receive(:upload_file) { uploaded_file }
    allow(client).to receive(:publish) { created_work }
    allow(client).to receive(:set_workflow) { advanced_workflow }
    allow(work).to receive(:missing_files) { [{ path: 'fake/file/path' }] }
    expect { work.publish }.to raise_error 'Cannot publish, missing file(s) for upload: ["fake/file/path"]'
  end

  context 'without data args' do
    before(:each) do
      args[:data] = nil
    end
    it 'will not publish the work without data' do
      expect { work.publish }.to raise_error 'Missing data'
    end
  end
  context 'without client args' do
    before(:each) do
      args[:client] = nil
    end
    it 'will not publish the work without client' do
      expect { work.publish }.to raise_error 'Missing client'
    end
  end
  context 'without files args' do
    before(:each) do
      args[:files] = nil
    end
    it 'will not publish the work without files' do
      expect { work.publish }.to raise_error 'Missing files'
    end
  end
  context 'without work_type args' do
    before(:each) do
      args[:work_type] = nil
    end
    it 'will not publish the work without work_type' do
      expect { work.publish }.to raise_error 'Missing work_type'
    end
  end
  context 'without admin_set_title args' do
    before(:each) do
      args[:admin_set_title] = nil
    end
    it 'will not publish the work without admin_set_title' do
      expect { work.publish }.to raise_error 'Missing admin_set_title'
    end
  end
end
