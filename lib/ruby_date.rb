# frozen_string_literal: true

require_relative "ruby_date/version"
require_relative "ruby_date/constants"
require_relative "ruby_date/core"
require_relative "ruby_date/strftime"

# Backward compatibility
Date = RubyDate unless defined?(Date)
