class Backoffable
  include Backoff

  def action
    puts 'action'
  end
end
