# frozen_string_literal: true

require "test_helper"
require "timeout"

class RubyDateTest < Test::Unit::TestCase
  test "VERSION" do
    assert do
      ::RubyDate.const_defined?(:VERSION)
    end
  end

  # copy from date/test/date/test_date_new.rb

  def test_jd
    d = RubyDate.jd
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])

    d2 = RubyDate.jd
    assert_equal(d, d2)

    d = RubyDate.jd(0)
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
  end

  def test_valid_with_invalid_types
    o = Object.new
    assert_equal(false, RubyDate.valid_jd?(o))
    assert_equal(false, RubyDate.valid_civil?(o, 1, 1))
    assert_equal(false, RubyDate.valid_civil?(1, o, 1))
    assert_equal(false, RubyDate.valid_civil?(1, 1, o))
    assert_equal(false, RubyDate.valid_ordinal?(o, 1))
    assert_equal(false, RubyDate.valid_ordinal?(1, o))
    assert_equal(false, RubyDate.valid_commercial?(o, 1, 1))
    assert_equal(false, RubyDate.valid_commercial?(1, o, 1))
    assert_equal(false, RubyDate.valid_commercial?(1, 1, o))
  end

  def test_invalid_types
    o = Object.new
    assert_raise(TypeError) { RubyDate.julian_leap?(o) }
    assert_raise(TypeError) { RubyDate.gregorian_leap?(o) }
    assert_raise(TypeError) { RubyDate.jd(o) }
    assert_raise(TypeError) { RubyDate.new(o) }
    assert_raise(TypeError) { RubyDate.new(1, o) }
    assert_raise(TypeError) { RubyDate.new(1, 1, o) }
    assert_raise(TypeError) { RubyDate.ordinal(o) }
    assert_raise(TypeError) { RubyDate.ordinal(1, o) }
    assert_raise(TypeError) { RubyDate.commercial(o) }
    assert_raise(TypeError) { RubyDate.commercial(1, o) }
    assert_raise(TypeError) { RubyDate.commercial(1, 1, o) }
  end

  def test_ordinal
    d = RubyDate.ordinal
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])

    d2 = RubyDate.ordinal
    assert_equal(d, d2)

    d = RubyDate.ordinal(-4712,1)
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])

    d = RubyDate.ordinal(-4712,1.0)
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
  end

  def test_ordinal__neg
    d = RubyDate.ordinal(-1,-1)
    assert_equal([-1, 365], [d.year, d.yday])
  end

  def test_ordinal__ex
    assert_raise(RubyDate::Error) do
      RubyDate.ordinal(2001,366)
    end
  end

  def test_civil
    d = RubyDate.civil
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])

    d2 = RubyDate.civil
    assert_equal(d, d2)

    d = RubyDate.civil(-4712,1,1)
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])

    d = RubyDate.civil(-4712,1,1.0)
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
  end

  def test_civil__neg
    d = RubyDate.civil(-1,-1,-1)
    assert_equal([-1, 12, 31], [d.year, d.mon, d.mday])
  end

  def test_civil__ex
    assert_raise(RubyDate::Error) do
      RubyDate.civil(2001,2,29)
    end
  end

  def test_civil__reform
    d = RubyDate.jd(RubyDate::ENGLAND, RubyDate::ENGLAND)
    assert_equal([1752, 9, 14], [d.year, d.mon, d.mday])
    d -= 1
    assert_equal([1752, 9, 2], [d.year, d.mon, d.mday])

    d = RubyDate.jd(RubyDate::ITALY, RubyDate::ITALY)
    assert_equal([1582, 10, 15], [d.year, d.mon, d.mday])
    d -= 1
    assert_equal([1582, 10, 4], [d.year, d.mon, d.mday])
  end

  def test_commercial
    d = RubyDate.commercial
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])

    d2 = RubyDate.commercial
    assert_equal(d, d2)

    d = RubyDate.commercial(1582,40,5)
    assert_equal([1582, 10, 15], [d.year, d.mon, d.mday])

    d = RubyDate.commercial(1582,40,5.0)
    assert_equal([1582, 10, 15], [d.year, d.mon, d.mday])
  end

  def test_commercial__neg
    d = RubyDate.commercial(1998,-1,-1)
    assert_equal([1999, 1, 3], [d.year, d.mon, d.mday])
  end

  def test_commercial__ex
    assert_raise(RubyDate::Error) do
      RubyDate.commercial(1997,53,1)
    end
  end

  def test_weeknum
    d = RubyDate.weeknum
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])

    d = RubyDate.weeknum(2002,11,4, 0)
    assert_equal(2452355, d.jd)

    assert_raise(RubyDate::Error) do
      RubyDate.weeknum(1999,53,0, 0)
    end
  end if RubyDate.respond_to?(:weeknum, true)

  def test_nth_kday
    d = RubyDate.nth_kday
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])

    d = RubyDate.nth_kday(1992,2, 5,6)
    assert_equal(2448682, d.jd)

    assert_raise(RubyDate::Error) do
      RubyDate.nth_kday(2006,5, 5,0)
    end
  end if RubyDate.respond_to?(:nth_kday, true)

  def test_today
    z = Time.now
    d = RubyDate.today
    t = Time.now
    t2 = Time.utc(t.year, t.mon, t.mday)
    t3 = Time.utc(d.year, d.mon, d.mday)
    assert_in_delta(t2, t3, t - z + 2)
  end

  def test_now
    assert_equal(false, RubyDate.respond_to?(:now))
  end

  # copy from date/test/date/test_date_arith.rb

  class Rat < Numeric
    def to_r; self; end
  end

  def test__plus
    d = RubyDate.new(2000,2,29) + -1
    assert_equal([2000, 2, 28], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,2,29) + 0
    assert_equal([2000, 2, 29], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,2,29) + 1
    assert_equal([2000, 3, 1], [d.year, d.mon, d.mday])
  end

  def test__plus__ex
    e = TypeError
    assert_raise(e) do
      RubyDate.new(2000,2,29) + 'foo'
    end
    assert_raise(e) do
      RubyDate.new(2000,2,29) + Time.mktime(2000,2,29)
    end
    n = Rat.new
    assert_raise(e) do
      Timeout.timeout(1) {RubyDate.new(2000,2,29) + n}
    end
  end

  def test__minus
    d = RubyDate.new(2000,3,1) - -1
    assert_equal([2000, 3, 2], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,3,1) - 0
    assert_equal([2000, 3, 1], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,3,1) - 1
    assert_equal([2000, 2, 29], [d.year, d.mon, d.mday])

    d = RubyDate.new(2000,3,1) - RubyDate.new(2000,2,29)
    assert_equal(1, d)
    d = RubyDate.new(2000,2,29) - RubyDate.new(2000,3,1)
    assert_equal(-1, d)
  end

  def test__minus__ex
    e = TypeError
    assert_raise(e) do
      RubyDate.new(2000,2,29) - 'foo'
    end
    assert_raise(e) do
      RubyDate.new(2000,2,29) - Time.mktime(2000,2,29)
    end
  end

  def test__compare
    assert_equal(0, (RubyDate.new(2000,1,1) <=> RubyDate.new(2000,1,1)))
    assert_equal(-1, (RubyDate.new(2000,1,1) <=> RubyDate.new(2000,1,2)))
    assert_equal(1, (RubyDate.new(2000,1,2) <=> RubyDate.new(2000,1,1)))
    assert_equal(0, (RubyDate.new(2001,1,4,RubyDate::JULIAN) <=>
                     RubyDate.new(2001,1,17, RubyDate::GREGORIAN)))
  end
end
