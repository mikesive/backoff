require_relative 'spec_helper'

RSpec.describe Backoff do
  let(:backoffable) { Backoffable.new }
  let(:config) { { base: 3 } }
  let(:retrier) { Backoff::Retrier.new(backoffable) }

  describe '#backoff' do
    before { allow(backoffable).to receive(:retrier).and_return(retrier) }
    subject { backoffable.backoff(config) }
    it 'should configure retrier' do
      expect(retrier).to receive(:configure).with(config)
      subject
    end

    it { is_expected.to be_a(Backoff::Retrier) }
  end
end
