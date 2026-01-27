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

  def test_prev
    d = RubyDate.new(2000,1,1)
    assert_raise(NoMethodError) do
      d.prev
    end
  end

  def test_prev_day
    d = RubyDate.new(2001,1,1).prev_day
    assert_equal([2000, 12, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2001,1,1).prev_day(2)
    assert_equal([2000, 12, 30], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,12,31).prev_day(-2)
    assert_equal([2001, 1, 2], [d.year, d.mon, d.mday])
  end

  def test_prev_month
    d = RubyDate.new(2000,1,31) << -1
    assert_equal([2000, 2, 29], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31) << 1
    assert_equal([1999, 12, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31) << 12
    assert_equal([1999, 1, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31) << 14
    assert_equal([1998, 11, 30], [d.year, d.mon, d.mday])
  end

  def test_prev_month__2
    d = RubyDate.new(2000,1,31).prev_month(-1)
    assert_equal([2000, 2, 29], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31).prev_month
    assert_equal([1999, 12, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31).prev_month(12)
    assert_equal([1999, 1, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31).prev_month(14)
    assert_equal([1998, 11, 30], [d.year, d.mon, d.mday])
  end

  def test_prev_year
    d = RubyDate.new(2000,1,31).prev_year(-1)
    assert_equal([2001, 1, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31).prev_year
    assert_equal([1999, 1, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31).prev_year(10)
    assert_equal([1990, 1, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31).prev_year(100)
    assert_equal([1900, 1, 31], [d.year, d.mon, d.mday])
  end

  def test_next
    d = RubyDate.new(2000,12,31).next
    assert_equal([2001, 1, 1], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,12,31).succ
    assert_equal([2001, 1, 1], [d.year, d.mon, d.mday])

    d = RubyDate.today
    d2 = d.next
    assert_equal(d, (d2 - 1))
    d = RubyDate.today
    d2 = d.succ
    assert_equal(d, (d2 - 1))
  end

  def test_next_day
    d = RubyDate.new(2000,12,31).next_day
    assert_equal([2001, 1, 1], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,12,31).next_day(2)
    assert_equal([2001, 1, 2], [d.year, d.mon, d.mday])
    d = RubyDate.new(2001,1,1).next_day(-2)
    assert_equal([2000, 12, 30], [d.year, d.mon, d.mday])
  end

  def test_next_month
    d = RubyDate.new(2000,1,31) >> -1
    assert_equal([1999, 12, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31) >> 1
    assert_equal([2000, 2, 29], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31) >> 12
    assert_equal([2001, 1, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31) >> 13
    assert_equal([2001, 2, 28], [d.year, d.mon, d.mday])
  end

  def test_next_month__2
    d = RubyDate.new(2000,1,31).next_month(-1)
    assert_equal([1999, 12, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31).next_month
    assert_equal([2000, 2, 29], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31).next_month(12)
    assert_equal([2001, 1, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31).next_month(13)
    assert_equal([2001, 2, 28], [d.year, d.mon, d.mday])
  end

  def test_next_year
    d = RubyDate.new(2000,1,31).next_year(-1)
    assert_equal([1999, 1, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31).next_year
    assert_equal([2001, 1, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31).next_year(10)
    assert_equal([2010, 1, 31], [d.year, d.mon, d.mday])
    d = RubyDate.new(2000,1,31).next_year(100)
    assert_equal([2100, 1, 31], [d.year, d.mon, d.mday])
  end

  def test_downto
    p = RubyDate.new(2001,1,14)
    q = RubyDate.new(2001,1,7)
    i = 0
    p.downto(q) do
      i += 1
    end
    assert_equal(8, i)
  end

  def test_downto__noblock
    p = RubyDate.new(2001,1,14)
    q = RubyDate.new(2001,1,7)
    e = p.downto(q)
    assert_equal(8, e.to_a.size)
  end

  def test_upto
    p = RubyDate.new(2001,1,14)
    q = RubyDate.new(2001,1,21)
    i = 0
    p.upto(q) do
      i += 1
    end
    assert_equal(8, i)
  end

  def test_upto__noblock
    p = RubyDate.new(2001,1,14)
    q = RubyDate.new(2001,1,21)
    e = p.upto(q)
    assert_equal(8, e.to_a.size)
  end

  def test_step
    p = RubyDate.new(2001,1,14)
    q = RubyDate.new(2001,1,21)
    i = 0
    p.step(q, 2) do
      i += 1
    end
    assert_equal(4, i)

    i = 0
    p.step(q) do
      i += 1
    end
    assert_equal(8, i)
  end

  def test_step__noblock
    p = RubyDate.new(2001,1,14)
    q = RubyDate.new(2001,1,21)
    e = p.step(q, 2)
    assert_equal(4, e.to_a.size)

    e = p.step(q)
    assert_equal(8, e.to_a.size)
  end

  def test_step__compare
    p = RubyDate.new(2000, 1, 1)
    q = RubyDate.new(1999, 12, 31)
    o = Object.new
    def o.<=>(*);end
    assert_raise(ArgumentError) {
      p.step(q, o).to_a
    }

    o = Object.new
    def o.<=>(*);2;end
    a = []
    p.step(q, o) {|d| a << d}
    assert_empty(a)
  end

  # copy from date/test/date/test_date_attr.rb

  def test__attr
    d = RubyDate.new(1965, 5, 23)

    assert_equal('1965-05-23', d.to_s)

    assert_equal('', d.inspect.gsub!(/./,''))
    assert_equal('', d.to_s.gsub!(/./,''))

    assert_equal(2438904, d.jd)

    assert_equal(0, d.day_fraction)

    assert_equal(38903, d.mjd)
    assert_equal(139744, d.ld)

    assert_equal(1965, d.year)
    assert_equal(143, d.yday)
    assert_equal(5, d.mon)
    assert_equal(d.mon, d.month)
    assert_equal(23, d.mday)
    assert_equal(d.mday, d.day)

    assert_equal(false, d.respond_to?(:hour))
    assert_equal(false, d.respond_to?(:min))
    assert_equal(false, d.respond_to?(:sec))
    assert_equal(false, d.respond_to?(:sec_fraction))
    assert_equal(false, d.respond_to?(:zone))
    assert_equal(false, d.respond_to?(:offset))

    assert_equal(1965, d.cwyear)
    assert_equal(20, d.cweek)
    assert_equal(7, d.cwday)

    assert_equal(0, d.wday)
    assert_equal(false, d.leap?)
    assert_equal(false, d.julian?)
    assert_equal(true, d.gregorian?)

    assert_equal(RubyDate::ITALY, d.start)
    assert_equal(d.start, d.start)
  end

  def test__wday_predicate
    d = RubyDate.new(2005, 10, 23)
    assert_equal(true, d.sunday?)
    assert_equal(false, d.monday?)
    assert_equal(false, d.tuesday?)
    assert_equal(false, d.wednesday?)
    assert_equal(false, d.thursday?)
    assert_equal(false, d.friday?)
    assert_equal(false, d.saturday?)

    d = RubyDate.new(2005, 10, 30)
    14.times do |i|
      assert((d + i).__send__(%w(sunday? monday? tuesday? wednesday? thursday? friday? saturday?)[i % 7]))
    end
  end

  def test_nth_kday
    assert_equal(false, RubyDate.new(2001,1,14).nth_kday?(1,0))
    assert_equal(true, RubyDate.new(2001,1,14).nth_kday?(2,0))
    assert_equal(false, RubyDate.new(2001,1,14).nth_kday?(3,0))
    assert_equal(false, RubyDate.new(2001,1,14).nth_kday?(4,0))
    assert_equal(false, RubyDate.new(2001,1,14).nth_kday?(5,0))
    assert_equal(false, RubyDate.new(2001,1,14).nth_kday?(-1,0))
    assert_equal(false, RubyDate.new(2001,1,14).nth_kday?(-2,0))
    assert_equal(true, RubyDate.new(2001,1,14).nth_kday?(-3,0))
    assert_equal(false, RubyDate.new(2001,1,14).nth_kday?(-4,0))
    assert_equal(false, RubyDate.new(2001,1,14).nth_kday?(-5,0))
  end if RubyDate.new.respond_to?(:nth_kday?, true)

end
