# Backoff

Backoff is a simple exponential backoff implementation.

## Usage

To use in any class, simply include the Backoff module:

```
class MyClass
  include Backoff
  ...
  def my_method
  end
end
```
You can then use exponential backoff like so:

```
my_instance = MyClass.new
my_instance.backoff.my_method
```

## Configuration

The `:backoff` method takes an optional hash of 3 different options:

- `:retries`: the max number of times to retry the method. The default is 5.

- `:catch_errors`: an error class or array of error classes to perform a retry after. The default is `:all` which will retry after any error type.

- `:base`: the base number of seconds to wait before trying again. The default is 2. For example, after 1 failure, the sleep time will be 2, then 4, then 8 etc. etc.