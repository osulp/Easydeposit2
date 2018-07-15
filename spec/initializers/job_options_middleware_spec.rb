RSpec.describe Sidekiq::JobOptionsMiddleware do
  let(:yielded) do
    subject.call(nil, item, nil, nil) do
      item
    end
  end

  let(:retry_count) { nil }
  let(:item) {
    {
      'args' => [
        { 'job_class' => 'ApplicationJob' }
      ],
      retry: retry_count
    }
  }

  it 'defaults to 0 retries' do
    expect(yielded[:retry]).to eq 0
  end

  context 'when retry and specified' do
    let(:retry_count) { 5 }
    it 'retains the retry count specified' do
      expect(yielded[:retry]).to eq retry_count
    end
  end
end
