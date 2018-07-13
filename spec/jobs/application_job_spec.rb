RSpec.describe ApplicationJob do
  let(:default_job_options) {
    { retry: 0 }
  }
  it 'has default job options' do
    expect(described_class.job_options(nil)).to eq default_job_options
  end

  it 'sets specific job options' do
    lots_of_retries = { retry: 1000000 }
    expect(described_class.job_options(lots_of_retries)).to eq lots_of_retries
  end

  it 'returns job options' do
    described_class.job_options(nil)
    expect(described_class.get_job_options).to eq default_job_options
  end
end
