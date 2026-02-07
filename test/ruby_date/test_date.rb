# frozen_string_literal: true

require 'test/unit'
require_relative '../../lib/ruby_date'

class DateSub < RubyDate; end
class DateTimeSub < RubyDateTime; end

class RubyDateDateTest < Test::Unit::TestCase
  def test_range_infinite_float
    today = RubyDate.today
    r = today...Float::INFINITY
    assert_equal today, r.begin
    assert_equal Float::INFINITY, r.end
    assert_equal true, r.cover?(today+1)
    assert_equal false, r.cover?(today-1)
    r = (-Float::INFINITY)...today
    assert_equal(-Float::INFINITY, r.begin)
    assert_equal today, r.end
    assert_equal false, r.cover?(today+1)
    assert_equal true, r.cover?(today-1)
  end

  def test__const
    assert_nil(RubyDate::MONTHNAMES[0])
    assert_equal('January', RubyDate::MONTHNAMES[1])
    assert_equal(13, RubyDate::MONTHNAMES.size)
    assert_equal('Sunday', RubyDate::DAYNAMES[0])
    assert_equal(7, RubyDate::DAYNAMES.size)

    assert_nil(RubyDate::ABBR_MONTHNAMES[0])
    assert_equal('Jan', RubyDate::ABBR_MONTHNAMES[1])
    assert_equal(13, RubyDate::ABBR_MONTHNAMES.size)
    assert_equal('Sun', RubyDate::ABBR_DAYNAMES[0])
    assert_equal(7, RubyDate::ABBR_DAYNAMES.size)

    assert(RubyDate::MONTHNAMES.frozen?)
    assert(RubyDate::MONTHNAMES[1].frozen?)
    assert(RubyDate::DAYNAMES.frozen?)
    assert(RubyDate::DAYNAMES[0].frozen?)

    assert(RubyDate::ABBR_MONTHNAMES.frozen?)
    assert(RubyDate::ABBR_MONTHNAMES[1].frozen?)
    assert(RubyDate::ABBR_DAYNAMES.frozen?)
    assert(RubyDate::ABBR_DAYNAMES[0].frozen?)
  end

  def test_sub
    d = DateSub.new
    dt = DateTimeSub.new

    assert_instance_of(DateSub, d)
    assert_instance_of(DateTimeSub, dt)

    assert_instance_of(DateSub, DateSub.today)
    assert_instance_of(DateTimeSub, DateTimeSub.now)

    assert_equal('-4712-01-01', d.to_s)
    assert_equal('-4712-01-01T00:00:00+00:00', dt.to_s)

    d2 = d + 1
    assert_instance_of(DateSub, d2)
    d2 = d - 1
    assert_instance_of(DateSub, d2)
    d2 = d >> 1
    assert_instance_of(DateSub, d2)
    d2 = d << 1
    assert_instance_of(DateSub, d2)
    d2 = d.succ
    assert_instance_of(DateSub, d2)
    d2 = d.next
    assert_instance_of(DateSub, d2)
    d2 = d.italy
    assert_instance_of(DateSub, d2)
    d2 = d.england
    assert_instance_of(DateSub, d2)
    d2 = d.julian
    assert_instance_of(DateSub, d2)
    d2 = d.gregorian
    assert_instance_of(DateSub, d2)
    s = Marshal.dump(d)
    d2 = Marshal.load(s)
    assert_equal(d2, d)
    assert_instance_of(DateSub, d2)

    dt2 = dt + 1
    assert_instance_of(DateTimeSub, dt2)
    dt2 = dt - 1
    assert_instance_of(DateTimeSub, dt2)
    dt2 = dt >> 1
    assert_instance_of(DateTimeSub, dt2)
    dt2 = dt << 1
    assert_instance_of(DateTimeSub, dt2)
    dt2 = dt.succ
    assert_instance_of(DateTimeSub, dt2)
    dt2 = dt.next
    assert_instance_of(DateTimeSub, dt2)
    dt2 = dt.italy
    assert_instance_of(DateTimeSub, dt2)
    dt2 = dt.england
    assert_instance_of(DateTimeSub, dt2)
    dt2 = dt.julian
    assert_instance_of(DateTimeSub, dt2)
    dt2 = dt.gregorian
    assert_instance_of(DateTimeSub, dt2)
    s = Marshal.dump(dt)
    dt2 = Marshal.load(s)
    assert_equal(dt2, dt)
    assert_instance_of(DateTimeSub, dt2)
  end

  def test_eql_p
    d = RubyDate.jd(0)
    d2 = RubyDate.jd(0)
    dt = RubyDate.jd(0)
    dt2 = RubyDate.jd(0)

    assert_equal(d, d2)
    assert_not_equal(d, 0)

    assert_equal(dt, dt2)
    assert_not_equal(dt, 0)

    assert_equal(d, dt)
    assert_equal(d2, dt2)
  end

  def test_hash
    h = {}
    h[RubyDate.new(1999,5,23)] = 0
    h[RubyDate.new(1999,5,24)] = 1
    h[RubyDate.new(1999,5,25)] = 2
    h[RubyDate.new(1999,5,25)] = 9
    assert_equal(3, h.size)
    assert_equal(9, h[RubyDate.new(1999,5,25)])
    assert_equal(9, h[RubyDate.new(1999,5,25)])

    h = {}
    h[RubyDate.new(3171505571716611468830131104691,2,19)] = 0
    assert_equal(true, h.key?(RubyDate.new(3171505571716611468830131104691,2,19)))

    h = {}
    h[RubyDate.new(1999,5,23)] = 0
    h[RubyDate.new(1999,5,24)] = 1
    h[RubyDate.new(1999,5,25)] = 2
    h[RubyDate.new(1999,5,25)] = 9
    assert_equal(3, h.size)
    assert_equal(9, h[RubyDate.new(1999,5,25)])
    assert_equal(9, h[RubyDate.new(1999,5,25)])

    assert_instance_of(String, RubyDate.new(1999,5,25).hash.to_s)
  end

  def test_freeze
    d = RubyDate.new
    d.freeze
    assert_equal(true, d.frozen?)
    assert_instance_of(Integer, d.yday)
    assert_instance_of(String, d.to_s)
  end

  def test_submillisecond_comparison
    d1 = RubyDate.new(2013, 12, 6, 0, 0, Rational(1, 10000))
    d2 = RubyDate.new(2013, 12, 6, 0, 0, Rational(2, 10000))
    # d1 is 0.0001s earlier than d2
    assert_equal(-1, d1 <=> d2)
    assert_equal(0, d1 <=> d1)
    assert_equal(1, d2 <=> d1)
  end

  def test_infinity_comparison
    assert_equal(0, Float::INFINITY <=> RubyDate::Infinity.new)
    assert_equal(0, RubyDate::Infinity.new <=> Float::INFINITY)
    assert_equal(0, -Float::INFINITY <=> -RubyDate::Infinity.new)
    assert_equal(0, -RubyDate::Infinity.new <=> -Float::INFINITY)

    assert_equal(1, Float::INFINITY <=> -RubyDate::Infinity.new)
    assert_equal(1, RubyDate::Infinity.new <=> -Float::INFINITY)

    assert_equal(-1, -Float::INFINITY <=> RubyDate::Infinity.new)
    assert_equal(-1, -RubyDate::Infinity.new <=> Float::INFINITY)
  end

  def test_deconstruct_keys
    d = RubyDate.new(1999,5,23)
    assert_equal({year: 1999, month: 5, day: 23, wday: 0, yday: 143}, d.deconstruct_keys(nil))
    assert_equal({year: 1999}, d.deconstruct_keys([:year, :century]))
    assert_equal(
      {year: 1999, month: 5, day: 23, wday: 0, yday: 143},
      d.deconstruct_keys([:year, :month, :day, :wday, :yday])
    )

    dt = RubyDate.new(1999, 5, 23, 4, 20, Rational(1, 10000))

    assert_equal(
      {year: 1999, month: 5, day: 23, wday: 0, yday: 143,
       hour: 4, min: 20, sec: 0, sec_fraction: Rational(1, 10000), zone: "+00:00"},
      dt.deconstruct_keys(nil)
    )

    assert_equal({year: 1999}, dt.deconstruct_keys([:year, :century]))

    assert_equal(
      {year: 1999, month: 5, day: 23, wday: 0, yday: 143,
       hour: 4, min: 20, sec: 0, sec_fraction: Rational(1, 10000), zone: "+00:00"},
      dt.deconstruct_keys([:year, :month, :day, :wday, :yday, :hour, :min, :sec, :sec_fraction, :zone])
    )

    dtz = RubyDate.parse('3rd Feb 2001 04:05:06+03:30')
    assert_equal({zone: '+03:30'}, dtz.deconstruct_keys([:zone]))
  end
end
