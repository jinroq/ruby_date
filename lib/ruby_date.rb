# frozen_string_literal: true

require_relative "ruby_date/version"
require_relative "ruby_date/constants"
require_relative "ruby_date/core"
require_relative "ruby_date/strftime"
require_relative "ruby_date/parse"
require_relative "ruby_date/strptime"
require_relative "ruby_date/datetime"

# Register Date as an alias for RubyDate for Marshal compatibility.
Date = RubyDate unless defined?(Date) # rubocop:disable Naming/ConstantName

# When RubyDate.new is called with more than 4 arguments (i.e., time components),
# create a RubyDateTime instance instead.
class RubyDate
  class << self
    alias_method :_original_new, :new

    def new(*args)
      if self == RubyDate && args.length > 4
        RubyDateTime.new(*args)
      else
        _original_new(*args)
      end
    end
  end
end
