require_relative '../spec_helper'

RSpec.describe Backoff::Retrier do
  let(:args) { [backoffable, config] }
  let(:config) { { retries: 3, catch_errors: [rescuable] } }
  let(:defaults) { described_class::DEFAULT_OPTS }
  let(:retrier) { described_class.new(*args) }
  let(:backoffable) { Backoffable.new }
  let(:rescuable) { RuntimeError }
  let(:unrescuable) { ArgumentError }

  before { allow(retrier).to receive(:sleep).and_return(true) }

  subject { retrier.action }

  describe '#config' do
    subject { retrier.config }
    it { is_expected.to be }

    context 'with no args' do
      let(:config) { {} }
      it 'should be empty' do
        expect(subject).to be_empty
      end
    end

    context 'with args' do
      it 'should set value' do
        expect(subject[:retries]).to eq(config[:retries])
      end
    end
  end

  describe '#get_opts' do
    before { allow(backoffable).to receive(:action).and_raise(rescuable) }
    context 'with some config' do
      it 'should get value from config or default' do
        expect(defaults).to receive(:[]).twice.with(:base).and_call_original
        expect(defaults).not_to receive(:[]).with(:catch_errors).and_call_original
        expect(defaults).not_to receive(:[]).with(:retries).and_call_original
        subject rescue nil
      end
    end
  end

  describe '#catchable?' do
    before { allow(backoffable).to receive(:action).and_raise(unrescuable) }
    context 'when not catchable' do
      it 'should not attempt backoff' do
        expect(retrier).to receive(:backoff).once
        subject
      end

      it 'should raise the error' do
        expect { subject }.to raise_error(unrescuable)
      end
    end

    context 'when rescuable error' do
      before { allow(backoffable).to receive(:action).and_raise(rescuable) }
      it 'should attempt retries' do
        expect(backoffable).to receive(:action).exactly(config[:retries]).times
        subject rescue nil
      end

      it 'should increment sleep' do
        base = defaults[:base]
        expect(retrier).to receive(:sleep).with(base).with(base**2)
        subject rescue nil
      end

      it 'should raise error' do
        expect { subject }.to raise_error(rescuable)
      end
    end

    context 'when unrescuable error' do
      before { allow(backoffable).to receive(:action).and_raise(unrescuable) }
      it 'should not attempt retries' do
        expect(backoffable).to receive(:action).once
        subject rescue nil
      end

      it 'should raise error' do
        expect { subject }.to raise_error(unrescuable)
      end
    end
  end
end
