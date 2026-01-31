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

  # copy from date/test/date/test_date_conv.rb

  def with_tz(tz)
    old = ENV["TZ"]
    begin
      ENV["TZ"] = tz
      yield
    ensure
      ENV["TZ"] = old
    end
  end

  def test_to_class
    #[Time.now, RubyDate.today, DateTime.now].each do |o|
    [Time.now, RubyDate.today].each do |o|
      assert_instance_of(Time, o.to_time)
      assert_instance_of(RubyDate, o.to_date)
      #assert_instance_of(DateTime, o.to_datetime)
    end
  end

  def test_to_time__from_time
    t = Time.mktime(2004, 9, 19, 1, 2, 3, 456789)
    t2 = t.to_time
    assert_equal([2004, 9, 19, 1, 2, 3, 456789],
                 [t2.year, t2.mon, t2.mday, t2.hour, t2.min, t2.sec, t2.usec])

    t = Time.utc(2004, 9, 19, 1, 2, 3, 456789)
    t2 = t.to_time.utc
    assert_equal([2004, 9, 19, 1, 2, 3, 456789],
                 [t2.year, t2.mon, t2.mday, t2.hour, t2.min, t2.sec, t2.usec])

    t = Time.new(2004, 9, 19, 1, 2, 3, '+03:00')
    with_tz('Asia/Tokyo') do
      t2 = t.to_time
      assert_equal([2004, 9, 19, 1, 2, 3],
       [t2.year, t2.mon, t2.mday, t2.hour, t2.min, t2.sec])
      assert_equal(3 * 60 * 60, t2.gmt_offset)
    end
  end

  def test_to_time__from_date
    d = RubyDate.new(2004, 9, 19)
    t = d.to_time
    assert_equal([2004, 9, 19, 0, 0, 0, 0],
                 [t.year, t.mon, t.mday, t.hour, t.min, t.sec, t.usec])
  end

  def test_to_time_to_date_roundtrip__from_gregorian_date
    d = RubyDate.new(1582, 10, 15)
    t = d.to_time
    assert_equal([1582, 10, 15, 0, 0, 0, 0],
                 [t.year, t.mon, t.mday, t.hour, t.min, t.sec, t.usec])
    assert_equal(d, t.to_date)
    assert_equal(d.jd, t.to_date.jd)
  end

  def test_to_time_to_date_roundtrip__from_julian_date
    d = RubyDate.new(1582, 10, 4)
    t = d.to_time
    assert_equal([1582, 10, 14, 0, 0, 0, 0],
                 [t.year, t.mon, t.mday, t.hour, t.min, t.sec, t.usec])
    assert_equal(d, t.to_date)
    assert_equal(d.jd, t.to_date.jd)
  end

  def test_to_time__from_datetime
    omit "DateTime is deprecated and not implemented in RubyDate"

    d = DateTime.new(2004, 9, 19, 1, 2, 3, 8.to_r/24) + 456789.to_r/86400000000
    t = d.to_time
    assert_equal([2004, 9, 19, 1, 2, 3, 456789, 8*60*60],
     [t.year, t.mon, t.mday, t.hour, t.min, t.sec, t.usec, t.utc_offset])

    d = DateTime.new(2004, 9, 19, 1, 2, 3, 0) + 456789.to_r/86400000000
    t = d.to_time.utc
    assert_equal([2004, 9, 19, 1, 2, 3, 456789],
                 [t.year, t.mon, t.mday, t.hour, t.min, t.sec, t.usec])

    d = DateTime.new(1582, 10, 3, 1, 2, 3, 0) + 456789.to_r/86400000000
    t = d.to_time.utc
    assert_equal([1582, 10, 13, 1, 2, 3, 456789],
                 [t.year, t.mon, t.mday, t.hour, t.min, t.sec, t.usec])

    d = DateTime.new(2004, 9, 19, 1, 2, 3, 0) + 456789123.to_r/86400000000000
    t = d.to_time.utc
    assert_equal([2004, 9, 19, 1, 2, 3, 456789123],
                 [t.year, t.mon, t.mday, t.hour, t.min, t.sec, t.nsec])

    # TruffleRuby does not support more than nanoseconds
    unless RUBY_ENGINE == 'truffleruby'
      d = DateTime.new(2004, 9, 19, 1, 2, 3, 0) + 456789123456789123.to_r/86400000000000000000000
      t = d.to_time.utc
      assert_equal([2004, 9, 19, 1, 2, 3, Rational(456789123456789123,1000000000000000000)],
                   [t.year, t.mon, t.mday, t.hour, t.min, t.sec, t.subsec])
    end
  end

  def test_to_date__from_time
    t = Time.mktime(2004, 9, 19, 1, 2, 3, 456789)
    d = t.to_date
    assert_equal([2004, 9, 19, 0], [d.year, d.mon, d.mday, d.day_fraction])

    t = Time.utc(2004, 9, 19, 1, 2, 3, 456789)
    d = t.to_date
    assert_equal([2004, 9, 19, 0], [d.year, d.mon, d.mday, d.day_fraction])

    t = Time.utc(1582, 10, 13, 1, 2, 3, 456789)
    d = t.to_date # using ITALY
    assert_equal([1582, 10, 3, 0], [d.year, d.mon, d.mday, d.day_fraction])
  end

  def test_to_date__from_date
    d = RubyDate.new(2004, 9, 19) + 1.to_r/2
    d2 = d.to_date
    assert_equal([2004, 9, 19, 1.to_r/2],
                 [d2.year, d2.mon, d2.mday, d2.day_fraction])
  end

  def test_to_date__from_datetime
    omit "DateTime is deprecated and not implemented in RubyDate"

    d = DateTime.new(2004, 9, 19, 1, 2, 3, 9.to_r/24) + 456789.to_r/86400000000
    d2 = d.to_date
    assert_equal([2004, 9, 19, 0], [d2.year, d2.mon, d2.mday, d2.day_fraction])

    d = DateTime.new(2004, 9, 19, 1, 2, 3, 0) + 456789.to_r/86400000000
    d2 = d.to_date
    assert_equal([2004, 9, 19, 0], [d2.year, d2.mon, d2.mday, d2.day_fraction])
  end

  def test_to_datetime__from_time
    t = Time.mktime(2004, 9, 19, 1, 2, 3, 456789)
    d = t.to_datetime
    assert_equal([2004, 9, 19, 1, 2, 3,
                  456789.to_r/1000000,
                  t.utc_offset.to_r/86400],
                 [d.year, d.mon, d.mday, d.hour, d.min, d.sec,
                  d.sec_fraction, d.offset])

    t = Time.utc(2004, 9, 19, 1, 2, 3, 456789)
    d = t.to_datetime
    assert_equal([2004, 9, 19, 1, 2, 3,
                  456789.to_r/1000000,
                  0],
                 [d.year, d.mon, d.mday, d.hour, d.min, d.sec,
                  d.sec_fraction, d.offset])

    t = Time.utc(1582, 10, 13, 1, 2, 3, 456789)
    d = t.to_datetime # using ITALY
    assert_equal([1582, 10, 3, 1, 2, 3,
                  456789.to_r/1000000,
                  0],
                 [d.year, d.mon, d.mday, d.hour, d.min, d.sec,
                  d.sec_fraction, d.offset])

    t = Time.now
    d = t.to_datetime
    require 'time'
    assert_equal(t.iso8601(10), d.iso8601(10))
  end

  def test_to_datetime__from_date
    d = RubyDate.new(2004, 9, 19) + 1.to_r/2
    d2 = d.to_datetime
    assert_equal([2004, 9, 19, 0, 0, 0, 0, 0],
                 [d2.year, d2.mon, d2.mday, d2.hour, d2.min, d2.sec,
                  d2.sec_fraction, d2.offset])
  end

  def test_to_datetime__from_datetime
    omit "DateTime is deprecated and not implemented in RubyDate"

    d = DateTime.new(2004, 9, 19, 1, 2, 3, 9.to_r/24) + 456789.to_r/86400000000
    d2 = d.to_datetime
    assert_equal([2004, 9, 19, 1, 2, 3,
                  456789.to_r/1000000,
                  9.to_r/24],
                 [d2.year, d2.mon, d2.mday, d2.hour, d2.min, d2.sec,
                  d2.sec_fraction, d2.offset])

    d = DateTime.new(2004, 9, 19, 1, 2, 3, 0) + 456789.to_r/86400000000
    d2 = d.to_datetime
    assert_equal([2004, 9, 19, 1, 2, 3,
                  456789.to_r/1000000,
                  0],
                 [d2.year, d2.mon, d2.mday, d2.hour, d2.min, d2.sec,
                  d2.sec_fraction, d2.offset])
  end

  # copy from date/test/date/test_date_marshal.rb

  def test_marshal
    d = RubyDate.new
    m = Marshal.dump(d)
    d2 = Marshal.load(m)
    assert_equal(d, d2)
    assert_equal(d.start, d2.start)
    assert_instance_of(String, d2.to_s)

    d = RubyDate.today
    m = Marshal.dump(d)
    d2 = Marshal.load(m)
    assert_equal(d, d2)
    assert_equal(d.start, d2.start)
    assert_instance_of(String, d2.to_s)

    # d = DateTime.now
    # m = Marshal.dump(d)
    # d2 = Marshal.load(m)
    # assert_equal(d, d2)
    # assert_equal(d.start, d2.start)
    # assert_instance_of(String, d2.to_s)

    d = RubyDate.today
    a = d.marshal_dump
    d.freeze
    assert(d.frozen?)
    expected_error = defined?(FrozenError) ? FrozenError : RuntimeError
    assert_raise(expected_error){d.marshal_load(a)}

    # d = DateTime.now
    # a = d.marshal_dump
    # d.freeze
    # assert(d.frozen?)
    # expected_error = defined?(FrozenError) ? FrozenError : RuntimeError
    # assert_raise(expected_error){d.marshal_load(a)}

    d = RubyDate.new + 1/2r + 2304/65437r/86400
    m = Marshal.dump(d)
    d2 = Marshal.load(m)
    assert_equal(d, d2)
    assert_equal(d.start, d2.start)
    assert_instance_of(String, d2.to_s)
  end

  def test_memsize
    omit "DateTime is deprecated and not implemented in RubyDate"

    require 'objspace'
    t = DateTime.new(2018, 11, 13)
    size = ObjectSpace.memsize_of(t)
    t2 = Marshal.load(Marshal.dump(t))
    assert_equal(t, t2)
    assert_equal(size, ObjectSpace.memsize_of(t2), "not reallocated but memsize changed")
  end

  # copy from date/test/date/test_switch_hitter.rb

  def test_new
    [RubyDate.new,
     RubyDate.civil,
     # DateTime.new,
     # DateTime.civil
	].each do |d|
      assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    end

    [RubyDate.new(2001),
     RubyDate.civil(2001),
     # DateTime.new(2001),
     # DateTime.civil(2001)
	].each do |d|
      assert_equal([2001, 1, 1], [d.year, d.mon, d.mday])
    end

    d = RubyDate.new(2001, 2, 3)
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    d = RubyDate.new(2001, 2, Rational('3.5'))
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    d = RubyDate.new(2001,2, 3, Date::JULIAN)
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    d = RubyDate.new(2001,2, 3, Date::GREGORIAN)
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])

    d = RubyDate.new(2001,-12, -31)
    assert_equal([2001, 1, 1], [d.year, d.mon, d.mday])
    d = RubyDate.new(2001,-12, -31, Date::JULIAN)
    assert_equal([2001, 1, 1], [d.year, d.mon, d.mday])
    d = RubyDate.new(2001,-12, -31, Date::GREGORIAN)
    assert_equal([2001, 1, 1], [d.year, d.mon, d.mday])

    # d = DateTime.new(2001, 2, 3, 4, 5, 6)
    # assert_equal([2001, 2, 3, 4, 5, 6, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.new(2001, 2, 3, 4, 5, 6, 0)
    # assert_equal([2001, 2, 3, 4, 5, 6, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.new(2001, 2, 3, 4, 5, 6, Rational(9,24))
    # assert_equal([2001, 2, 3, 4, 5, 6, Rational(9,24)],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.new(2001, 2, 3, 4, 5, 6, 0.375)
    # assert_equal([2001, 2, 3, 4, 5, 6, Rational(9,24)],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.new(2001, 2, 3, 4, 5, 6, '+09:00')
    # assert_equal([2001, 2, 3, 4, 5, 6, Rational(9,24)],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.new(2001, 2, 3, 4, 5, 6, '-09:00')
    # assert_equal([2001, 2, 3, 4, 5, 6, Rational(-9,24)],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.new(2001, -12, -31, -4, -5, -6, '-09:00')
    # assert_equal([2001, 1, 1, 20, 55, 54, Rational(-9,24)],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.new(2001, -12, -31, -4, -5, -6, '-09:00', Date::JULIAN)
    # assert_equal([2001, 1, 1, 20, 55, 54, Rational(-9,24)],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.new(2001, -12, -31, -4, -5, -6, '-09:00', Date::GREGORIAN)
    # assert_equal([2001, 1, 1, 20, 55, 54, Rational(-9,24)],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_jd_from_switch_hitter
    d = RubyDate.jd
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    d = RubyDate.jd(0)
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    d = RubyDate.jd(2451944)
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])

  #   d = DateTime.jd
  #   assert_equal([-4712, 1, 1, 0, 0, 0, 0],
  #                [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  #   d = DateTime.jd(0)
  #   assert_equal([-4712, 1, 1, 0, 0, 0, 0],
  #                [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  #   d = DateTime.jd(2451944)
  #   assert_equal([2001, 2, 3, 0, 0, 0, 0],
  #                [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  #   d = DateTime.jd(2451944, 4, 5, 6)
  #   assert_equal([2001, 2, 3, 4, 5, 6, 0],
  #                [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  #   d = DateTime.jd(2451944, 4, 5, 6, 0)
  #   assert_equal([2001, 2, 3, 4, 5, 6, 0],
  #                [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  #   d = DateTime.jd(2451944, 4, 5, 6, '+9:00')
  #   assert_equal([2001, 2, 3, 4, 5, 6, Rational(9, 24)],
  #                [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  #   d = DateTime.jd(2451944, -4, -5, -6, '-9:00')
  #   assert_equal([2001, 2, 3, 20, 55, 54, Rational(-9, 24)],
  #                [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_ajd
    assert_equal(RubyDate.civil(2008, 1, 16).ajd, 4908963r/2)
    assert_equal(RubyDate.civil(-11082381539297990, 2, 19).ajd, -8095679714453739481r/2)
  end

  def test_ordinal_from_switch_hitter
    d = RubyDate.ordinal
    assert_equal([-4712, 1], [d.year, d.yday])
    d = RubyDate.ordinal(-4712, 1)
    assert_equal([-4712, 1], [d.year, d.yday])

    d = RubyDate.ordinal(2001, 2)
    assert_equal([2001, 2], [d.year, d.yday])
    d = RubyDate.ordinal(2001, 2, Date::JULIAN)
    assert_equal([2001, 2], [d.year, d.yday])
    d = RubyDate.ordinal(2001, 2, Date::GREGORIAN)
    assert_equal([2001, 2], [d.year, d.yday])

    d = RubyDate.ordinal(2001, -2, Date::JULIAN)
    assert_equal([2001, 364], [d.year, d.yday])
    d = RubyDate.ordinal(2001, -2, Date::GREGORIAN)
    assert_equal([2001, 364], [d.year, d.yday])

    # d = DateTime.ordinal
    # assert_equal([-4712, 1, 1, 0, 0, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.ordinal(-4712, 1)
    # assert_equal([-4712, 1, 1, 0, 0, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.ordinal(2001, 34)
    # assert_equal([2001, 2, 3, 0, 0, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.ordinal(2001, 34, 4, 5, 6)
    # assert_equal([2001, 2, 3, 4, 5, 6, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.ordinal(2001, 34, 4, 5, 6, 0)
    # assert_equal([2001, 2, 3, 4, 5, 6, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.ordinal(2001, 34, 4, 5, 6, '+9:00')
    # assert_equal([2001, 2, 3, 4, 5, 6, Rational(9, 24)],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.ordinal(2001, 34, -4, -5, -6, '-9:00')
    # assert_equal([2001, 2, 3, 20, 55, 54, Rational(-9, 24)],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_commercial_from_switch_hitter
    d = RubyDate.commercial
    assert_equal([-4712, 1, 1], [d.cwyear, d.cweek, d.cwday])
    d = RubyDate.commercial(-4712, 1, 1)
    assert_equal([-4712, 1, 1], [d.cwyear, d.cweek, d.cwday])

    d = RubyDate.commercial(2001, 2, 3)
    assert_equal([2001, 2, 3], [d.cwyear, d.cweek, d.cwday])
    d = RubyDate.commercial(2001, 2, 3, Date::JULIAN)
    assert_equal([2001, 2, 3], [d.cwyear, d.cweek, d.cwday])
    d = RubyDate.commercial(2001, 2, 3, Date::GREGORIAN)
    assert_equal([2001, 2, 3], [d.cwyear, d.cweek, d.cwday])

    d = RubyDate.commercial(2001, -2, -3)
    assert_equal([2001, 51, 5], [d.cwyear, d.cweek, d.cwday])
    d = RubyDate.commercial(2001, -2, -3, Date::JULIAN)
    assert_equal([2001, 51, 5], [d.cwyear, d.cweek, d.cwday])
    d = RubyDate.commercial(2001, -2, -3, Date::GREGORIAN)
    assert_equal([2001, 51, 5], [d.cwyear, d.cweek, d.cwday])

    # d = DateTime.commercial
    # assert_equal([-4712, 1, 1, 0, 0, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.commercial(-4712, 1, 1)
    # assert_equal([-4712, 1, 1, 0, 0, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.commercial(2001, 5, 6)
    # assert_equal([2001, 2, 3, 0, 0, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.commercial(2001, 5, 6, 4, 5, 6)
    # assert_equal([2001, 2, 3, 4, 5, 6, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.commercial(2001, 5, 6, 4, 5, 6, 0)
    # assert_equal([2001, 2, 3, 4, 5, 6, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.commercial(2001, 5, 6, 4, 5, 6, '+9:00')
    # assert_equal([2001, 2, 3, 4, 5, 6, Rational(9, 24)],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.commercial(2001, 5, 6, -4, -5, -6, '-9:00')
    # assert_equal([2001, 2, 3, 20, 55, 54, Rational(-9, 24)],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_fractional
    d = RubyDate.jd(2451944.0)
    assert_equal(2451944, d.jd)
    d = RubyDate.jd(Rational(2451944))
    assert_equal(2451944, d.jd)
    d = RubyDate.jd(2451944.5)
    assert_equal(2451944, d.jd)
    d = RubyDate.jd(Rational('2451944.5'))
    assert_equal(2451944, d.jd)

    d = RubyDate.civil(2001, 2, 3.0)
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    d = RubyDate.civil(2001, 2, Rational(3))
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    d = RubyDate.civil(2001, 2, 3.5)
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    d = RubyDate.civil(2001, 2, Rational('3.5'))
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])

    d = RubyDate.ordinal(2001, 2.0)
    assert_equal([2001, 2], [d.year, d.yday])
    d = RubyDate.ordinal(2001, Rational(2))
    assert_equal([2001, 2], [d.year, d.yday])

    d = RubyDate.commercial(2001, 2, 3.0)
    assert_equal([2001, 2, 3], [d.cwyear, d.cweek, d.cwday])
    d = RubyDate.commercial(2001, 2, Rational(3))
    assert_equal([2001, 2, 3], [d.cwyear, d.cweek, d.cwday])

    # d = DateTime.jd(2451944.0)
    # assert_equal(2451944, d.jd)
    # d = DateTime.jd(Rational(2451944))
    # assert_equal(2451944, d.jd)
    # d = DateTime.jd(2451944.5)
    # assert_equal([2451944, 12], [d.jd, d.hour])
    # d = DateTime.jd(Rational('2451944.5'))
    # assert_equal([2451944, 12], [d.jd, d.hour])

    # d = DateTime.civil(2001, 2, 3.0)
    # assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    # d = DateTime.civil(2001, 2, Rational(3))
    # assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    # d = DateTime.civil(2001, 2, 3.5)
    # assert_equal([2001, 2, 3, 12], [d.year, d.mon, d.mday, d.hour])
    # d = DateTime.civil(2001, 2, Rational('3.5'))
    # assert_equal([2001, 2, 3, 12], [d.year, d.mon, d.mday, d.hour])
    # d = DateTime.civil(2001, 2, 3, 4.5)
    # assert_equal([2001, 2, 3, 4, 30], [d.year, d.mon, d.mday, d.hour, d.min])
    # d = DateTime.civil(2001, 2, 3, Rational('4.5'))
    # assert_equal([2001, 2, 3, 4, 30], [d.year, d.mon, d.mday, d.hour, d.min])
    # d = DateTime.civil(2001, 2, 3, 4, 5.5)
    # assert_equal([2001, 2, 3, 4, 5, 30],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec])
    # d = DateTime.civil(2001, 2, 3, 4, Rational('5.5'))
    # assert_equal([2001, 2, 3, 4, 5, 30],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec])

    # d = DateTime.ordinal(2001, 2.0)
    # assert_equal([2001, 2], [d.year, d.yday])
    # d = DateTime.ordinal(2001, Rational(2))
    # assert_equal([2001, 2], [d.year, d.yday])

    # d = DateTime.commercial(2001, 2, 3.0)
    # assert_equal([2001, 2, 3], [d.cwyear, d.cweek, d.cwday])
    # d = DateTime.commercial(2001, 2, Rational(3))
    # assert_equal([2001, 2, 3], [d.cwyear, d.cweek, d.cwday])

  end

  # def test_canon24oc
  #   d = DateTime.jd(2451943,24)
  #   assert_equal([2001, 2, 3, 0, 0, 0, 0],
  #                [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  #   d = DateTime.ordinal(2001,33,24)
  #   assert_equal([2001, 2, 3, 0, 0, 0, 0],
  #                [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  #   d = DateTime.new(2001,2,2,24)
  #   assert_equal([2001, 2, 3, 0, 0, 0, 0],
  #                [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  #   d = DateTime.commercial(2001,5,5,24)
  #   assert_equal([2001, 2, 3, 0, 0, 0, 0],
  #                [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  # end

  # def test_zone
  #   d = DateTime.new(2001, 2, 3)
  #   assert_equal(Encoding::US_ASCII, d.zone.encoding)
  # end

  def test_to_s
    d = RubyDate.new(2001, 2, 3)
    assert_equal(Encoding::US_ASCII, d.to_s.encoding)
    assert_equal(Encoding::US_ASCII, d.strftime.encoding)
    # d = DateTime.new(2001, 2, 3)
    # assert_equal(Encoding::US_ASCII, d.to_s.encoding)
    # assert_equal(Encoding::US_ASCII, d.strftime.encoding)
  end

  def test_inspect
    d = RubyDate.new(2001, 2, 3)
    assert_equal(Encoding::US_ASCII, d.inspect.encoding)
    # d = DateTime.new(2001, 2, 3)
    # assert_equal(Encoding::US_ASCII, d.inspect.encoding)
  end

  def test_strftime
    assert_raise(Errno::ERANGE) do
      RubyDate.today.strftime('%100000z')
    end
    assert_raise(Errno::ERANGE) do
      RubyDate.new(1 << 10000).strftime('%Y')
    end
    assert_equal('-3786825600', RubyDate.new(1850).strftime('%s'))
    assert_equal('-3786825600000', RubyDate.new(1850).strftime('%Q'))
  end

  def test_cmp
    assert_equal(-1, RubyDate.new(2001,2,3) <=> RubyDate.new(2001,2,4))
    assert_equal(0, RubyDate.new(2001,2,3) <=> RubyDate.new(2001,2,3))
    assert_equal(1, RubyDate.new(2001,2,3) <=> RubyDate.new(2001,2,2))

    assert_equal(-1, RubyDate.new(2001,2,3) <=> 2451944.0)
    assert_equal(-1, RubyDate.new(2001,2,3) <=> 2451944)
    assert_equal(0, RubyDate.new(2001,2,3) <=> 2451943.5)
    assert_equal(1, RubyDate.new(2001,2,3) <=> 2451943.0)
    assert_equal(1, RubyDate.new(2001,2,3) <=> 2451943)

    assert_equal(-1, RubyDate.new(2001,2,3) <=> Rational('4903888/2'))
    assert_equal(0, RubyDate.new(2001,2,3) <=> Rational('4903887/2'))
    assert_equal(1, RubyDate.new(2001,2,3) <=> Rational('4903886/2'))

    assert_equal(-1, RubyDate.new(-4713,11,1,Date::GREGORIAN) <=> RubyDate.new(-4713,12,1,Date::GREGORIAN))
  end

  def test_eqeqeq
    assert_equal(false, RubyDate.new(2001,2,3) === RubyDate.new(2001,2,4))
    assert_equal(true, RubyDate.new(2001,2,3) === RubyDate.new(2001,2,3))
    assert_equal(false, RubyDate.new(2001,2,3) === RubyDate.new(2001,2,2))

    assert_equal(true, RubyDate.new(2001,2,3) === 2451944.0)
    assert_equal(true, RubyDate.new(2001,2,3) === 2451944)
    assert_equal(false, RubyDate.new(2001,2,3) === 2451943.5)
    assert_equal(false, RubyDate.new(2001,2,3) === 2451943.0)
    assert_equal(false, RubyDate.new(2001,2,3) === 2451943)

    assert_equal(true, RubyDate.new(2001,2,3) === Rational('4903888/2'))
    assert_equal(false, RubyDate.new(2001,2,3) === Rational('4903887/2'))
    assert_equal(false, RubyDate.new(2001,2,3) === Rational('4903886/2'))
  end

  def test_period
    # -5000
    d = RubyDate.new(-5000,1,1)
    assert_equal([-5000, 1, 1, 5], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5001, 11, 22, 5], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.new(-5000,1,1,Date::JULIAN)
    assert_equal([-5000, 1, 1, 5], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5001, 11, 22, 5], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.new(-5000,1,1,Date::GREGORIAN)
    assert_equal([-5000, 1, 1, 3], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([-5000, 2, 10, 3], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(-105192)
    assert_equal([-5000, 1, 1, 5], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5001, 11, 22, 5], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(-105192,Date::JULIAN)
    assert_equal([-5000, 1, 1, 5], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5001, 11, 22, 5], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(-105152,Date::GREGORIAN)
    assert_equal([-5000, 1, 1, 3], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([-5000, 2, 10, 3], [d2.year, d2.mon, d2.mday, d.wday])

    # -5000000
    d = RubyDate.new(-5_000_000,1,1)
    assert_equal([-5_000_000, 1, 1, 3], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5_000_103, 4, 28, 3], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.new(-5_000_000,1,1,Date::JULIAN)
    assert_equal([-5_000_000, 1, 1, 3], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5_000_103, 4, 28, 3], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.new(-5_000_000,1,1,Date::GREGORIAN)
    assert_equal([-5_000_000, 1, 1, 6], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([-4_999_898, 9, 4, 6], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(-1824528942)
    assert_equal([-5_000_000, 1, 1, 3], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5_000_103, 4, 28, 3], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(-1824528942,Date::JULIAN)
    assert_equal([-5_000_000, 1, 1, 3], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5_000_103, 4, 28, 3], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(-1824491440,Date::GREGORIAN)
    assert_equal([-5_000_000, 1, 1, 6], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([-4_999_898, 9, 4, 6], [d2.year, d2.mon, d2.mday, d.wday])

    # 5000000
    d = RubyDate.new(5_000_000,1,1)
    assert_equal([5_000_000, 1, 1, 6], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([4_999_897, 5, 3, 6], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.new(5_000_000,1,1,Date::JULIAN)
    assert_equal([5_000_000, 1, 1, 5], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([5_000_102, 9, 1, 5], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.new(5_000_000,1,1,Date::GREGORIAN)
    assert_equal([5_000_000, 1, 1, 6], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([4_999_897, 5, 3, 6], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(1827933560)
    assert_equal([5_000_000, 1, 1, 6], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([4_999_897, 5, 3, 6], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(1827971058,Date::JULIAN)
    assert_equal([5_000_000, 1, 1, 5], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([5_000_102, 9, 1, 5], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(1827933560,Date::GREGORIAN)
    assert_equal([5_000_000, 1, 1, 6], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([4_999_897, 5, 3, 6], [d2.year, d2.mon, d2.mday, d.wday])

    # dt
    # d = DateTime.new(-123456789,2,3,4,5,6,0)
    # assert_equal([-123456789, 2, 3, 4, 5, 6, 1],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.wday])
    # d2 = d.gregorian
    # assert_equal([-123459325, 12, 27, 4, 5, 6, 1],
    #              [d2.year, d2.mon, d2.mday, d2.hour, d2.min, d2.sec, d.wday])

    # d = DateTime.new(123456789,2,3,4,5,6,0)
    # assert_equal([123456789, 2, 3, 4, 5, 6, 5],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.wday])
    # d2 = d.julian
    # assert_equal([123454254, 1, 19, 4, 5, 6, 5],
    #              [d2.year, d2.mon, d2.mday, d2.hour, d2.min, d2.sec, d.wday])
  end

  def period2_iter2(from, to, sg)
    (from..to).each do |j|
      d = RubyDate.jd(j, sg)
      d2 = RubyDate.new(d.year, d.mon, d.mday, sg)
      assert_equal(d2.jd, j)
      assert_equal(d2.ajd, d.ajd)
      assert_equal(d2.year, d.year)

      # d = DateTime.jd(j, 12,0,0, '+12:00', sg)
      # d2 = DateTime.new(d.year, d.mon, d.mday,
      #                   d.hour, d.min, d.sec, d.offset, sg)
      # assert_equal(d2.jd, j)
      # assert_equal(d2.ajd, d.ajd)
      # assert_equal(d2.year, d.year)
    end
  end

  def period2_iter(from, to)
    period2_iter2(from, to, Date::GREGORIAN)
    period2_iter2(from, to, Date::ITALY)
    period2_iter2(from, to, Date::ENGLAND)
    period2_iter2(from, to, Date::JULIAN)
  end

  def test_period2
    cm_period0 = 71149239
    cm_period = 0xfffffff.div(cm_period0) * cm_period0
    period2_iter(-cm_period * (1 << 64) - 3, -cm_period * (1 << 64) + 3)
    period2_iter(-cm_period - 3, -cm_period + 3)
    period2_iter(0 - 3, 0 + 3)
    period2_iter(+cm_period - 3, +cm_period + 3)
    period2_iter(+cm_period * (1 << 64) - 3, +cm_period * (1 << 64) + 3)
  end

  def test_different_alignments
    assert_equal(0, RubyDate.jd(0) <=> RubyDate.civil(-4713, 11, 24, Date::GREGORIAN))
    assert_equal(0, RubyDate.jd(213447717) <=> RubyDate.civil(579687, 11, 24))
    assert_equal(0, RubyDate.jd(-213447717) <=> RubyDate.civil(-589113, 11, 24, Date::GREGORIAN))

    # assert_equal(0, RubyDate.jd(0) <=> DateTime.civil(-4713, 11, 24, 0, 0, 0, 0, Date::GREGORIAN))
    # assert_equal(0, RubyDate.jd(213447717) <=> DateTime.civil(579687, 11, 24))
    # assert_equal(0, RubyDate.jd(-213447717) <=> DateTime.civil(-589113, 11, 24, 0, 0, 0, 0, Date::GREGORIAN))

    assert(RubyDate.jd(0) == RubyDate.civil(-4713, 11, 24, Date::GREGORIAN))
    assert(RubyDate.jd(213447717) == RubyDate.civil(579687, 11, 24))
    assert(RubyDate.jd(-213447717) == RubyDate.civil(-589113, 11, 24, Date::GREGORIAN))

    # assert(RubyDate.jd(0) == DateTime.civil(-4713, 11, 24, 0, 0, 0, 0, Date::GREGORIAN))
    # assert(RubyDate.jd(213447717) == DateTime.civil(579687, 11, 24))
    # assert(RubyDate.jd(-213447717) == DateTime.civil(-589113, 11, 24, 0, 0, 0, 0, Date::GREGORIAN))

    assert(RubyDate.jd(0) === RubyDate.civil(-4713, 11, 24, Date::GREGORIAN))
    assert(RubyDate.jd(213447717) === RubyDate.civil(579687, 11, 24))
    assert(RubyDate.jd(-213447717) === RubyDate.civil(-589113, 11, 24, Date::GREGORIAN))

    # assert(RubyDate.jd(0) === DateTime.civil(-4713, 11, 24, 12, 0, 0, 0, Date::GREGORIAN))
    # assert(RubyDate.jd(213447717) === DateTime.civil(579687, 11, 24, 12))
    # assert(RubyDate.jd(-213447717) === DateTime.civil(-589113, 11, 24, 12, 0, 0, 0, Date::GREGORIAN))

    a = RubyDate.jd(0)
    b = RubyDate.civil(-4713, 11, 24, Date::GREGORIAN)
    assert_equal(0, a <=> b)

    a = RubyDate.civil(-4712, 1, 1, Date::JULIAN)
    b = RubyDate.civil(-4713, 11, 24, Date::GREGORIAN)
    a.jd; b.jd
    assert_equal(0, a <=> b)

    a = RubyDate.jd(0)
    b = RubyDate.civil(-4713, 11, 24, Date::GREGORIAN)
    assert(a == b)

    a = RubyDate.civil(-4712, 1, 1, Date::JULIAN)
    b = RubyDate.civil(-4713, 11, 24, Date::GREGORIAN)
    a.jd; b.jd
    assert(a == b)

    a = RubyDate.jd(0)
    b = RubyDate.civil(-4713, 11, 24, Date::GREGORIAN)
    assert(a === b)

    a = RubyDate.civil(-4712, 1, 1, Date::JULIAN)
    b = RubyDate.civil(-4713, 11, 24, Date::GREGORIAN)
    a.jd; b.jd
    assert(a === b)
  end

  def test_marshal14
    s = "\x04\x03u:\x01\x04Date\x01\v\x04\x03[\x01\x02i\x03\xE8i%T"
    d = suppress_warning {Marshal.load(s)}
    assert_equal(Rational(4903887,2), d.ajd)
    assert_equal(Date::GREGORIAN, d.start)
  end

  def test_marshal16
    s = "\x04\x06u:\tDate\x0F\x04\x06[\ai\x03\xE8i%T"
    d = suppress_warning {Marshal.load(s)}
    assert_equal(Rational(4903887,2), d.ajd)
    assert_equal(Date::GREGORIAN, d.start)
  end

  def test_marshal18
    s = "\x04\bu:\tDateP\x04\b[\bo:\rRational\a:\x0F@numeratori\x03\xCF\xD3J:\x11@denominatori\ai\x00o:\x13Date::Infinity\x06:\a@di\xFA"
    d = Marshal.load(s)
    assert_equal(Rational(4903887,2), d.ajd)
    assert_equal(Date::GREGORIAN, d.start)

    s = "\x04\bu:\rDateTime`\x04\b[\bo:\rRational\a:\x0F@numeratorl+\b\xC9\xB0\x81\xBD\x02\x00:\x11@denominatori\x02\xC0\x12o;\x00\a;\x06i\b;\ai\ro:\x13Date::Infinity\x06:\a@di\xFA"
    d = Marshal.load(s)
    assert_equal(Rational(11769327817,4800), d.ajd)
    assert_equal(Rational(9,24), d.offset)
    assert_equal(Date::GREGORIAN, d.start)
  end

  def test_marshal192
    s = "\x04\bU:\tDate[\bU:\rRational[\ai\x03\xCF\xD3Ji\ai\x00o:\x13Date::Infinity\x06:\a@di\xFA"
    d = Marshal.load(s)
    assert_equal(Rational(4903887,2), d.ajd)
    assert_equal(Date::GREGORIAN, d.start)

    s = "\x04\bU:\rDateTime[\bU:\rRational[\al+\b\xC9\xB0\x81\xBD\x02\x00i\x02\xC0\x12U;\x06[\ai\bi\ro:\x13Date::Infinity\x06:\a@di\xFA"
    d = Marshal.load(s)
    assert_equal(Rational(11769327817,4800), d.ajd)
    assert_equal(Rational(9,24), d.offset)
    assert_equal(Date::GREGORIAN, d.start)
  end

  def test_enc
    Date::MONTHNAMES.each do |s|
      assert_equal(Encoding::US_ASCII, s.encoding) if s
    end
    Date::DAYNAMES.each do |s|
      assert_equal(Encoding::US_ASCII, s.encoding) if s
    end
    Date::ABBR_MONTHNAMES.each do |s|
      assert_equal(Encoding::US_ASCII, s.encoding) if s
    end
    Date::ABBR_DAYNAMES.each do |s|
      assert_equal(Encoding::US_ASCII, s.encoding) if s
    end

    h = RubyDate._strptime('15:43+09:00'.dup.force_encoding('euc-jp'), '%R%z')
    assert_equal(Encoding::EUC_JP, h[:zone].encoding)
    h = RubyDate._strptime('15:43+09:00'.dup.force_encoding('ascii-8bit'), '%R%z')
    assert_equal(Encoding::ASCII_8BIT, h[:zone].encoding)

    h = RubyDate._strptime('1;1/0'.dup.force_encoding('euc-jp'), '%d')
    assert_equal(Encoding::EUC_JP, h[:leftover].encoding)
    h = RubyDate._strptime('1;1/0'.dup.force_encoding('ascii-8bit'), '%d')
    assert_equal(Encoding::ASCII_8BIT, h[:leftover].encoding)

    h = RubyDate._parse('15:43+09:00'.dup.force_encoding('euc-jp'))
    assert_equal(Encoding::EUC_JP, h[:zone].encoding)
    h = RubyDate._parse('15:43+09:00'.dup.force_encoding('ascii-8bit'))
    assert_equal(Encoding::ASCII_8BIT, h[:zone].encoding)

    s = RubyDate.today.strftime('new 105'.dup.force_encoding('euc-jp'))
    assert_equal(Encoding::EUC_JP, s.encoding)
    s = RubyDate.today.strftime('new 105'.dup.force_encoding('ascii-8bit'))
    assert_equal(Encoding::ASCII_8BIT, s.encoding)

    # s = DateTime.now.strftime('super $record'.dup.force_encoding('euc-jp'))
    # assert_equal(Encoding::EUC_JP, s.encoding)
    # s = DateTime.now.strftime('super $record'.dup.force_encoding('ascii-8bit'))
    # assert_equal(Encoding::ASCII_8BIT, s.encoding)
  end

  def test_dup
    d = RubyDate.new(2001,2,3)
    d2 = d.dup
    assert_not_equal(d.object_id, d2.object_id)
    assert_kind_of(Date, d2)
    assert_equal(d, d2)

    # d = DateTime.new(2001,2,3)
    # d2 = d.dup
    # assert_not_equal(d.object_id, d2.object_id)
    # assert_kind_of(DateTime, d2)
    # assert_equal(d, d2)
  end

  def test_base
    assert_equal(true, RubyDate.test_all)
  end if defined?(RubyDate.test_all)

  private

  def suppress_warning
    $VERBOSE, verbose = nil, $VERBOSE
    yield
  ensure
    $VERBOSE = verbose
  end
end
