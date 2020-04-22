require_relative '../spec_helper'

RSpec.describe Backoff::Retrier do
  let(:config) { { retries: 3, catch_errors: [rescuable] } }
  let(:retrier) { described_class.new(backoffable) }
  let(:backoffable) { Backoffable.new }
  let(:rescuable) { RuntimeError }
  let(:unrescuable) { Net::OpenTimeout }

  before { allow(retrier).to receive(:sleep).and_return(true) }

  subject { retrier.configure(config); retrier.action }

  describe '#configure' do
    subject { retrier.configure(config); retrier.config }
    it { is_expected.to be }

    context 'with no args' do
      let(:config) { {} }
      it 'should be default' do
        expect(subject).to eq(described_class::DEFAULT_OPTS)
      end
    end

    context 'with args' do
      it 'should set value' do
        expect(subject[:retries]).to eq(config[:retries])
      end
    end

    context 'incorrect args' do
      [:base, :retries].each do |opt|
        context "#{opt}" do
          [0.2, "0.2", :zeropointtwo].each do |arg|
            context "#{arg}" do
              let(:config) { { opt => arg } }

              it 'throw ArgumentError' do
                expect { subject }.to raise_error(ArgumentError)
              end
            end
          end
        end
      end

      context ':catch_errors' do
        [:none, 1, 1.2].each do |arg|
          context "#{arg}" do
            let(:config) { { catch_errors: arg } }

            it 'throw ArgumentError' do
              expect { subject }.to raise_error(ArgumentError)
            end
          end
        end
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
        base = described_class::DEFAULT_OPTS[:base]
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
