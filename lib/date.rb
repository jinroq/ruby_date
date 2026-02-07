# frozen_string_literal: true

# Shim so that `require 'date'` loads ruby_date instead of the C extension.
require_relative 'ruby_date'
