module Backoff
  class Retrier
    DEFAULT_OPTS = { catch_errors: :all, base: 2, retries: 5 }
    EXCEPTED_ERRORS = [ArgumentError, NoMethodError]

    attr_accessor :config

    def initialize(backoffable)
      @backoffable = backoffable
      @config = DEFAULT_OPTS.dup
    end

    def configure(opts = {})
      @config.merge!(opts)

      [:base, :retries].each do |opt|
        if !@config[opt].is_a?(Integer)
          raise ArgumentError, ":#{opt} should be an integer"
        end
      end

      unless catch_all?
        errs_opt = @config[:catch_errors]
        return if errs_opt.is_a?(Array) && errs_opt.all? { |err| err.ancestors.include?(Exception) }
        return if errs_opt.is_a?(Class) && errs_opt.ancestors.include?(Exception)

        raise ArgumentError, ":catch_errors should be an Exception class or array of Exception classes"
      end
    end

    def method_missing(method, *args)
      backoff(0) { backoffable.send(method, *args) }
    end

    def respond_to_missing?(method_name, include_private = false)
      backoffable.respond_to?(method_name) || super
    end

    private

    attr_accessor :backoffable

    def backoff(tries, &block)
      return unless block_given?
      block.call
    rescue => e
      raise(e) if EXCEPTED_ERRORS.include?(e.class)

      increment = tries + 1
      raise(e) unless retry?(increment, e)
      wait_for = @config[:base]**increment
      sleep(wait_for)
      backoff(increment, &block)
    end

    def catchable?(e)
      catch_errors = @config[:catch_errors]
      catch_errors == e.class ||
        (catch_errors.is_a?(Array) && catch_errors.include?(e.class))
    end

    def catch_all?
      @config[:catch_errors] == :all
    end

    def retry?(tries, e)
      (tries < @config[:retries]) && (catch_all? || catchable?(e))
    end
  end
end
