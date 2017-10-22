module Backoff
  class Retrier
    DEFAULT_OPTS = { catch_errors: :all, base: 2, retries: 5 }
    attr_accessor :config

    def initialize(backoffable, config = {})
      @backoffable = backoffable
      @config = config
    end

    def configure(opts = {})
      @config.merge!(opts)
    end

    def method_missing(method, *args)
      backoff(0) { backoffable.send(method, *args) }
    end

    private

    attr_accessor :backoffable

    def backoff(tries, &block)
      return unless block_given?
      block.call
    rescue => e
      increment = tries + 1
      raise(e) unless retry?(increment, e)
      wait_for = get_opt(:base)**increment
      sleep(wait_for)
      backoff(increment, &block)
    end

    def catchable?(e)
      catch_errors = get_opt(:catch_errors)
      catch_errors == e.class ||
        (catch_errors.is_a?(Array) && catch_errors.include?(e.class))
    end

    def catch_all?
      get_opt(:catch_errors) == :all
    end

    def get_opt(key)
      self.config[key] || DEFAULT_OPTS[key]
    end

    def retry?(tries, e)
      (tries < get_opt(:retries)) && (catch_all? || catchable?(e))
    end
  end
end
