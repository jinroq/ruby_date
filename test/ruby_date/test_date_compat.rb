# frozen_string_literal: true

require 'test/unit'
require_relative '../../lib/ruby_date'

class RubyDateDateCompatTest < Test::Unit::TestCase

  def test_compat
    assert_equal(RubyDate.new, RubyDate.new)
    assert_equal(RubyDate.new(2002,3,19), RubyDate.new(2002,3,19))
    assert_equal(RubyDate.new(2002,3,19, 0,0,0), RubyDate.new(2002,3,19))
    assert_equal(RubyDate.new(2002,3,19, 0,0,0, 0), RubyDate.new(2002,3,19))
    assert_equal(RubyDate.new(2002,3,19, 0,0,0, 0.to_r), RubyDate.new(2002,3,19))
    assert_equal(RubyDate.new(2002,3,19, 0,0,0, 0, RubyDate::GREGORIAN), RubyDate.new(2002,3,19, RubyDate::GREGORIAN))
    assert_equal(RubyDate.new(2002,3,19, 0,0,0, 0, RubyDate::JULIAN), RubyDate.new(2002,3,19, RubyDate::JULIAN))

    assert(RubyDate.new(2002,3,19) != RubyDate.new(2002,3,19, 12,0,0))
    assert(RubyDate.new(2002,3,19) != RubyDate.new(2002,3,19, 0,0,1))
    assert(RubyDate.new(2002,3,19) === RubyDate.new(2002,3,19, 12,0,0))
    assert(RubyDate.new(2002,3,19) === RubyDate.new(2002,3,19, 0,0,1))
  end

end
