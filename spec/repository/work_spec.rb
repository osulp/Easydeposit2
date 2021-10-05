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
      abstract: 'This is an abstract',
      client: client,
      data: {
        'authors' => ['Batman, D. S.'],
        'biblio_dates' => ['MAR 1'],
        'biblio_years' => ['2018'],
        'conference_titles' => ['A conference'],
        'conference_locations' => ['Corvallis, OR'],
        'doctypes' => ['Article'],
        'dois' => ['10.01.030'],
        'editors' => ['OSU Libraries'],
        'funding_text' => ['Funded by OSU Libraries'],
        'isbns' => ['987-123-456'],
        'issns' => ['03-27'],
        'keywords' => ['Logging', 'And low-flow discharge'],
        'pages' => ['14-17'],
        'publisher' => ['OSU Press'],
        'researcher_ids' => ['987123456'],
        'researcher_names' => ['Grel, Rob'],
        'source_titles' => ['FOREST ENT'],
        'titles' => ['Fish response to contemporary timber harvest practices in a second-growth forest from the central Coast Range of Oregon'],
        'volumes' => ['420']
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
    expect(work.publish).to eq created_work
  end

  it 'can publish the work and advance the workflow' do
    ENV['REPOSITORY_PUBLISH_REQUIRES_WORKFLOW_APPROVAL'] = 'true'
    allow(client).to receive(:admin_sets) { admin_sets }
    allow(client).to receive(:upload_file) { uploaded_file }
    allow(client).to receive(:publish) { created_work }
    allow(client).to receive(:set_workflow) { advanced_workflow }
    expect(work.publish).to eq created_work
  end

  it 'will not publish the work without supplied files' do
    allow(client).to receive(:admin_sets) { admin_sets }
    allow(client).to receive(:upload_file) { uploaded_file }
    allow(client).to receive(:publish) { created_work }
    allow(client).to receive(:set_workflow) { advanced_workflow }
    allow(work).to receive(:missing_files) { [{ path: 'fake/file/path' }] }
    expect { work.publish }.to raise_error 'Cannot publish, missing file(s) for upload: ["fake/file/path"]'
  end

  it 'will show date in YYYY-MM-DD format' do
    expect { work.repository_data[:date_issued] }.to equal "2018-03-01"
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
