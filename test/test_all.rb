# frozen_string_literal: true

require 'test-unit'

Dir[File.join(__dir__, 'ruby_date', 'test_*.rb')].each do |file|
  require file
end
