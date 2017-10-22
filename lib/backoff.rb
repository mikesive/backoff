require_relative './backoff/retrier'

module Backoff
  def backoff(config = {})
    retrier.configure(config)
    retrier
  end

  private

  def retrier
    @retrier ||= Backoff::Retrier.new(self)
  end
end
