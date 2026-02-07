# frozen_string_literal: true

require 'test/unit'
require_relative '../../lib/ruby_date'

class RubyDateDateNewTest < Test::Unit::TestCase

  def test_jd
    d = RubyDate.jd
    # dt = DateTime.jd
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    # assert_equal([-4712, 1, 1], [dt.year, dt.mon, dt.mday])
    # assert_equal([0, 0, 0], [dt.hour, dt.min, dt.sec])

    d2 = RubyDate.jd
    # dt2 = DateTime.jd
    assert_equal(d, d2)
    # assert_equal(dt, dt2)

    d = RubyDate.jd(0)
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    # d = DateTime.jd(0, 0,0,0, 0)
    # assert_equal([-4712, 1, 1, 0, 0, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.jd(0, 0,0,0, '+0900')
    # assert_equal([-4712, 1, 1, 0, 0, 0, 9.to_r/24],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_jd__ex
    omit "DateTime is deprecated and not implemented in RubyDate"

    assert_raise(RubyDate::Error) do
      DateTime.jd(0, 23,59,60,0)
    end
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

    # assert_raise(TypeError) { DateTime.jd(o) }
    # assert_raise(TypeError) { DateTime.jd(1, o) }
    # assert_raise(TypeError) { DateTime.jd(1, 1, o) }
    # assert_raise(TypeError) { DateTime.jd(1, 1, 1, o) }
    # assert_raise(TypeError) { DateTime.new(o) }
    # assert_raise(TypeError) { DateTime.new(1, o) }
    # assert_raise(TypeError) { DateTime.new(1, 1, o) }
    # assert_raise(TypeError) { DateTime.new(1, 1, 1, o) }
    # assert_raise(TypeError) { DateTime.new(1, 1, 1, 1, o) }
    # assert_raise(TypeError) { DateTime.new(1, 1, 1, 1, 1, o) }
    # assert_raise(TypeError) { DateTime.ordinal(o) }
    # assert_raise(TypeError) { DateTime.ordinal(1, o) }
    # assert_raise(TypeError) { DateTime.ordinal(1, 1, o) }
    # assert_raise(TypeError) { DateTime.ordinal(1, 1, 1, o) }
    # assert_raise(TypeError) { DateTime.ordinal(1, 1, 1, 1, o) }
    # assert_raise(TypeError) { DateTime.commercial(o) }
    # assert_raise(TypeError) { DateTime.commercial(1, o) }
    # assert_raise(TypeError) { DateTime.commercial(1, 1, o) }
    # assert_raise(TypeError) { DateTime.commercial(1, 1, 1, o) }
    # assert_raise(TypeError) { DateTime.commercial(1, 1, 1, 1, o) }
    # assert_raise(TypeError) { DateTime.commercial(1, 1, 1, 1, 1, o) }
  end

  def test_ordinal
    d = RubyDate.ordinal
    # dt = DateTime.ordinal
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    # assert_equal([-4712, 1, 1], [dt.year, dt.mon, dt.mday])
    # assert_equal([0, 0, 0], [dt.hour, dt.min, dt.sec])

    d2 = RubyDate.ordinal
    # dt2 = DateTime.ordinal
    assert_equal(d, d2)
    # assert_equal(dt, dt2)

    d = RubyDate.ordinal(-4712,1)
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])

    d = RubyDate.ordinal(-4712,1.0)
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])

    # d = DateTime.ordinal(-4712,1, 0,0,0, 0)
    # assert_equal([-4712, 1, 1, 0, 0, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.ordinal(-4712,1, 0,0,0, '+0900')
    # assert_equal([-4712, 1, 1, 0, 0, 0, 9.to_r/24],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_ordinal__neg
    d = RubyDate.ordinal(-1,-1)
    assert_equal([-1, 365], [d.year, d.yday])

    # d = DateTime.ordinal(-1,-1, -1,-1,-1, 0)
    # assert_equal([-1, 365, 23, 59, 59, 0],
    #              [d.year, d.yday, d.hour, d.min, d.sec, d.offset])
  end

  def test_ordinal__ex
    assert_raise(RubyDate::Error) do
      RubyDate.ordinal(2001,366)
    end
    # assert_raise(RubyDate::Error) do
    #   DateTime.ordinal(2001,365, 23,59,60, 0)
    # end
  end

  def test_civil
    d = RubyDate.civil
    # dt = DateTime.civil
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    # assert_equal([-4712, 1, 1], [dt.year, dt.mon, dt.mday])
    # assert_equal([0, 0, 0], [dt.hour, dt.min, dt.sec])

    d2 = RubyDate.civil
    # dt2 = DateTime.civil
    assert_equal(d, d2)
    # assert_equal(dt, dt2)

    d = RubyDate.civil(-4712,1,1)
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])

    d = RubyDate.civil(-4712,1,1.0)
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])

    # d = DateTime.civil(-4712,1,1, 0,0,0, 0)
    # assert_equal([-4712, 1, 1, 0, 0, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.civil(-4712,1,1, 0,0,0, '+0900')
    # assert_equal([-4712, 1, 1, 0, 0, 0, 9.to_r/24],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])

    # d = DateTime.civil(2001,2,3 + 1.to_r/2)
    # assert_equal([2001, 2, 3, 12, 0, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.civil(2001,2,3, 4 + 1.to_r/2)
    # assert_equal([2001, 2, 3, 4, 30, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.civil(2001,2,3, 4,5 + 1.to_r/2)
    # assert_equal([2001, 2, 3, 4, 5, 30, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.civil(2001,2,3, 4,5,6 + 1.to_r/2)
    # assert_equal([2001, 2, 3, 4, 5, 6, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # assert_equal(1.to_r/2, d.sec_fraction)

    # d = DateTime.civil(2001, 2)
    # assert_equal([2001, 2, 1, 0, 0, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_civil__neg
    d = RubyDate.civil(-1,-1,-1)
    assert_equal([-1, 12, 31], [d.year, d.mon, d.mday])

    # d = DateTime.civil(-1,-1,-1, -1,-1,-1, 0)
    # assert_equal([-1, 12, 31, 23, 59, 59, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_civil__ex
    assert_raise(RubyDate::Error) do
      RubyDate.civil(2001,2,29)
    end
    # assert_raise(RubyDate::Error) do
    #   DateTime.civil(2001,2,28, 23,59,60, 0)
    # end
    # assert_raise(RubyDate::Error) do
    #   DateTime.civil(2001,2,28, 24,59,59, 0)
    # end
  end

  def test_civil__reform
    d = RubyDate.jd(RubyDate::ENGLAND, RubyDate::ENGLAND)
    # dt = DateTime.jd(RubyDate::ENGLAND, 0,0,0,0, RubyDate::ENGLAND)
    assert_equal([1752, 9, 14], [d.year, d.mon, d.mday])
    # assert_equal([1752, 9, 14], [dt.year, dt.mon, dt.mday])
    d -= 1
    # dt -= 1
    assert_equal([1752, 9, 2], [d.year, d.mon, d.mday])
    # assert_equal([1752, 9, 2], [dt.year, dt.mon, dt.mday])

    d = RubyDate.jd(RubyDate::ITALY, RubyDate::ITALY)
    # dt = DateTime.jd(RubyDate::ITALY, 0,0,0,0, RubyDate::ITALY)
    assert_equal([1582, 10, 15], [d.year, d.mon, d.mday])
    # assert_equal([1582, 10, 15], [dt.year, dt.mon, dt.mday])
    d -= 1
    # dt -= 1
    assert_equal([1582, 10, 4], [d.year, d.mon, d.mday])
    # assert_equal([1582, 10, 4], [dt.year, dt.mon, dt.mday])
  end

  def test_commercial
    d = RubyDate.commercial
    # dt = DateTime.commercial
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    # assert_equal([-4712, 1, 1], [dt.year, dt.mon, dt.mday])
    # assert_equal([0, 0, 0], [dt.hour, dt.min, dt.sec])

    d2 = RubyDate.commercial
    # dt2 = DateTime.commercial
    assert_equal(d, d2)
    # assert_equal(dt, dt2)

    d = RubyDate.commercial(1582,40,5)
    assert_equal([1582, 10, 15], [d.year, d.mon, d.mday])

    d = RubyDate.commercial(1582,40,5.0)
    assert_equal([1582, 10, 15], [d.year, d.mon, d.mday])

    # d = DateTime.commercial(1582,40,5, 0,0,0, 0)
    # assert_equal([1582, 10, 15, 0, 0, 0, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    # d = DateTime.commercial(1582,40,5, 0,0,0, '+0900')
    # assert_equal([1582, 10, 15, 0, 0, 0, 9.to_r/24],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_commercial__neg
    d = RubyDate.commercial(1998,-1,-1)
    assert_equal([1999, 1, 3], [d.year, d.mon, d.mday])

    # d = DateTime.commercial(1998,-1,-1, -1,-1,-1, 0)
    # assert_equal([1999, 1, 3, 23, 59, 59, 0],
    #              [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_commercial__ex
    assert_raise(RubyDate::Error) do
      RubyDate.commercial(1997,53,1)
    end
    # assert_raise(RubyDate::Error) do
    #   DateTime.commercial(1997,52,1, 23,59,60, 0)
    # end
  end

  def test_weeknum
    d = RubyDate.weeknum
    # dt = DateTime.weeknum
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    # assert_equal([-4712, 1, 1], [dt.year, dt.mon, dt.mday])
    # assert_equal([0, 0, 0], [dt.hour, dt.min, dt.sec])

    d = RubyDate.weeknum(2002,11,4, 0)
    assert_equal(2452355, d.jd)

    # d = DateTime.weeknum(2002,11,4, 0, 11,22,33)
    # assert_equal(2452355, d.jd)
    # assert_equal([11,22,33], [d.hour, d.min, d.sec])

    assert_raise(RubyDate::Error) do
      RubyDate.weeknum(1999,53,0, 0)
    end
    assert_raise(RubyDate::Error) do
      RubyDate.weeknum(1999,-53,-1, 0)
    end
  end if RubyDate.respond_to?(:weeknum, true)

  def test_nth_kday
    d = RubyDate.nth_kday
    # dt = DateTime.nth_kday
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    # assert_equal([-4712, 1, 1], [dt.year, dt.mon, dt.mday])
    # assert_equal([0, 0, 0], [dt.hour, dt.min, dt.sec])

    d = RubyDate.nth_kday(1992,2, 5,6)
    assert_equal(2448682, d.jd)

    # d = DateTime.nth_kday(1992,2, 5,6, 11,22,33)
    # assert_equal(2448682, d.jd)
    # assert_equal([11,22,33], [d.hour, d.min, d.sec])

    assert_raise(RubyDate::Error) do
      RubyDate.nth_kday(2006,5, 5,0)
    end
    assert_raise(RubyDate::Error) do
      RubyDate.nth_kday(2006,5, -5,0)
    end
  end if RubyDate.respond_to?(:nth_kday, true)

  def test_today
    z = Time.now
    d = RubyDate.today
    t = Time.now
    t2 = Time.utc(t.year, t.mon, t.mday)
    t3 = Time.utc(d.year, d.mon, d.mday)
    assert_in_delta(t2, t3, t - z + 2)

    # assert_equal(false, DateTime.respond_to?(:today))
  end

  def test_now
    assert_equal(false, RubyDate.respond_to?(:now))

    # z = Time.now
    # d = DateTime.now
    # t = Time.now
    # t2 = Time.local(d.year, d.mon, d.mday, d.hour, d.min, d.sec)
    # assert_in_delta(t, t2, t - z + 2)
  end

  def test_memsize
    omit "DateTime is deprecated and not implemented in RubyDate"

    require 'objspace'
    t = DateTime.now
    size = ObjectSpace.memsize_of(t)
    t.__send__(:initialize_copy, RubyDate.today)
    assert_instance_of(DateTime, t)
    assert_equal(size, ObjectSpace.memsize_of(t), "not reallocated but memsize changed")
  end
end
