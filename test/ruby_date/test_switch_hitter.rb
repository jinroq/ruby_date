# frozen_string_literal: true

require 'test/unit'
require_relative '../../lib/ruby_date'

class RubyDateSHTest < Test::Unit::TestCase

  def test_new
    [RubyDate.new,
     RubyDate.civil,
     RubyDate.new,
     RubyDate.civil
	].each do |d|
      assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    end

    [RubyDate.new(2001),
     RubyDate.civil(2001),
     RubyDate.new(2001),
     RubyDate.civil(2001)
	].each do |d|
      assert_equal([2001, 1, 1], [d.year, d.mon, d.mday])
    end

    d = RubyDate.new(2001, 2, 3)
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    d = RubyDate.new(2001, 2, Rational('3.5'))
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    d = RubyDate.new(2001,2, 3, RubyDate::JULIAN)
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    d = RubyDate.new(2001,2, 3, RubyDate::GREGORIAN)
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])

    d = RubyDate.new(2001,-12, -31)
    assert_equal([2001, 1, 1], [d.year, d.mon, d.mday])
    d = RubyDate.new(2001,-12, -31, RubyDate::JULIAN)
    assert_equal([2001, 1, 1], [d.year, d.mon, d.mday])
    d = RubyDate.new(2001,-12, -31, RubyDate::GREGORIAN)
    assert_equal([2001, 1, 1], [d.year, d.mon, d.mday])

    d = RubyDate.new(2001, 2, 3, 4, 5, 6)
    assert_equal([2001, 2, 3, 4, 5, 6, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.new(2001, 2, 3, 4, 5, 6, 0)
    assert_equal([2001, 2, 3, 4, 5, 6, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.new(2001, 2, 3, 4, 5, 6, Rational(9,24))
    assert_equal([2001, 2, 3, 4, 5, 6, Rational(9,24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.new(2001, 2, 3, 4, 5, 6, 0.375)
    assert_equal([2001, 2, 3, 4, 5, 6, Rational(9,24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.new(2001, 2, 3, 4, 5, 6, '+09:00')
    assert_equal([2001, 2, 3, 4, 5, 6, Rational(9,24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.new(2001, 2, 3, 4, 5, 6, '-09:00')
    assert_equal([2001, 2, 3, 4, 5, 6, Rational(-9,24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.new(2001, -12, -31, -4, -5, -6, '-09:00')
    assert_equal([2001, 1, 1, 20, 55, 54, Rational(-9,24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.new(2001, -12, -31, -4, -5, -6, '-09:00', RubyDate::JULIAN)
    assert_equal([2001, 1, 1, 20, 55, 54, Rational(-9,24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.new(2001, -12, -31, -4, -5, -6, '-09:00', RubyDate::GREGORIAN)
    assert_equal([2001, 1, 1, 20, 55, 54, Rational(-9,24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_jd
    d = RubyDate.jd
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    d = RubyDate.jd(0)
    assert_equal([-4712, 1, 1], [d.year, d.mon, d.mday])
    d = RubyDate.jd(2451944)
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])

    d = RubyDate.jd
    assert_equal([-4712, 1, 1, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.jd(0)
    assert_equal([-4712, 1, 1, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.jd(2451944)
    assert_equal([2001, 2, 3, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.jd(2451944, 4, 5, 6)
    assert_equal([2001, 2, 3, 4, 5, 6, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.jd(2451944, 4, 5, 6, 0)
    assert_equal([2001, 2, 3, 4, 5, 6, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.jd(2451944, 4, 5, 6, '+9:00')
    assert_equal([2001, 2, 3, 4, 5, 6, Rational(9, 24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.jd(2451944, -4, -5, -6, '-9:00')
    assert_equal([2001, 2, 3, 20, 55, 54, Rational(-9, 24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_ajd
    assert_equal(RubyDate.civil(2008, 1, 16).ajd, 4908963r/2)
    assert_equal(RubyDate.civil(-11082381539297990, 2, 19).ajd, -8095679714453739481r/2)
  end

  def test_ordinal
    d = RubyDate.ordinal
    assert_equal([-4712, 1], [d.year, d.yday])
    d = RubyDate.ordinal(-4712, 1)
    assert_equal([-4712, 1], [d.year, d.yday])

    d = RubyDate.ordinal(2001, 2)
    assert_equal([2001, 2], [d.year, d.yday])
    d = RubyDate.ordinal(2001, 2, RubyDate::JULIAN)
    assert_equal([2001, 2], [d.year, d.yday])
    d = RubyDate.ordinal(2001, 2, RubyDate::GREGORIAN)
    assert_equal([2001, 2], [d.year, d.yday])

    d = RubyDate.ordinal(2001, -2, RubyDate::JULIAN)
    assert_equal([2001, 364], [d.year, d.yday])
    d = RubyDate.ordinal(2001, -2, RubyDate::GREGORIAN)
    assert_equal([2001, 364], [d.year, d.yday])

    d = RubyDate.ordinal
    assert_equal([-4712, 1, 1, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.ordinal(-4712, 1)
    assert_equal([-4712, 1, 1, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.ordinal(2001, 34)
    assert_equal([2001, 2, 3, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.ordinal(2001, 34, 4, 5, 6)
    assert_equal([2001, 2, 3, 4, 5, 6, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.ordinal(2001, 34, 4, 5, 6, 0)
    assert_equal([2001, 2, 3, 4, 5, 6, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.ordinal(2001, 34, 4, 5, 6, '+9:00')
    assert_equal([2001, 2, 3, 4, 5, 6, Rational(9, 24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.ordinal(2001, 34, -4, -5, -6, '-9:00')
    assert_equal([2001, 2, 3, 20, 55, 54, Rational(-9, 24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_commercial
    d = RubyDate.commercial
    assert_equal([-4712, 1, 1], [d.cwyear, d.cweek, d.cwday])
    d = RubyDate.commercial(-4712, 1, 1)
    assert_equal([-4712, 1, 1], [d.cwyear, d.cweek, d.cwday])

    d = RubyDate.commercial(2001, 2, 3)
    assert_equal([2001, 2, 3], [d.cwyear, d.cweek, d.cwday])
    d = RubyDate.commercial(2001, 2, 3, RubyDate::JULIAN)
    assert_equal([2001, 2, 3], [d.cwyear, d.cweek, d.cwday])
    d = RubyDate.commercial(2001, 2, 3, RubyDate::GREGORIAN)
    assert_equal([2001, 2, 3], [d.cwyear, d.cweek, d.cwday])

    d = RubyDate.commercial(2001, -2, -3)
    assert_equal([2001, 51, 5], [d.cwyear, d.cweek, d.cwday])
    d = RubyDate.commercial(2001, -2, -3, RubyDate::JULIAN)
    assert_equal([2001, 51, 5], [d.cwyear, d.cweek, d.cwday])
    d = RubyDate.commercial(2001, -2, -3, RubyDate::GREGORIAN)
    assert_equal([2001, 51, 5], [d.cwyear, d.cweek, d.cwday])

    d = RubyDate.commercial
    assert_equal([-4712, 1, 1, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.commercial(-4712, 1, 1)
    assert_equal([-4712, 1, 1, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.commercial(2001, 5, 6)
    assert_equal([2001, 2, 3, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.commercial(2001, 5, 6, 4, 5, 6)
    assert_equal([2001, 2, 3, 4, 5, 6, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.commercial(2001, 5, 6, 4, 5, 6, 0)
    assert_equal([2001, 2, 3, 4, 5, 6, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.commercial(2001, 5, 6, 4, 5, 6, '+9:00')
    assert_equal([2001, 2, 3, 4, 5, 6, Rational(9, 24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.commercial(2001, 5, 6, -4, -5, -6, '-9:00')
    assert_equal([2001, 2, 3, 20, 55, 54, Rational(-9, 24)],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
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

    d = RubyDate.jd(2451944.0)
    assert_equal(2451944, d.jd)
    d = RubyDate.jd(Rational(2451944))
    assert_equal(2451944, d.jd)
    d = RubyDate.jd(2451944.5)
    assert_equal([2451944, 12], [d.jd, d.hour])
    d = RubyDate.jd(Rational('2451944.5'))
    assert_equal([2451944, 12], [d.jd, d.hour])

    d = RubyDate.civil(2001, 2, 3.0)
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    d = RubyDate.civil(2001, 2, Rational(3))
    assert_equal([2001, 2, 3], [d.year, d.mon, d.mday])
    d = RubyDate.civil(2001, 2, 3.5)
    assert_equal([2001, 2, 3, 12], [d.year, d.mon, d.mday, d.hour])
    d = RubyDate.civil(2001, 2, Rational('3.5'))
    assert_equal([2001, 2, 3, 12], [d.year, d.mon, d.mday, d.hour])
    d = RubyDate.civil(2001, 2, 3, 4.5)
    assert_equal([2001, 2, 3, 4, 30], [d.year, d.mon, d.mday, d.hour, d.min])
    d = RubyDate.civil(2001, 2, 3, Rational('4.5'))
    assert_equal([2001, 2, 3, 4, 30], [d.year, d.mon, d.mday, d.hour, d.min])
    d = RubyDate.civil(2001, 2, 3, 4, 5.5)
    assert_equal([2001, 2, 3, 4, 5, 30],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec])
    d = RubyDate.civil(2001, 2, 3, 4, Rational('5.5'))
    assert_equal([2001, 2, 3, 4, 5, 30],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec])

    d = RubyDate.ordinal(2001, 2.0)
    assert_equal([2001, 2], [d.year, d.yday])
    d = RubyDate.ordinal(2001, Rational(2))
    assert_equal([2001, 2], [d.year, d.yday])

    d = RubyDate.commercial(2001, 2, 3.0)
    assert_equal([2001, 2, 3], [d.cwyear, d.cweek, d.cwday])
    d = RubyDate.commercial(2001, 2, Rational(3))
    assert_equal([2001, 2, 3], [d.cwyear, d.cweek, d.cwday])

  end

  def test_canon24oc
    d = RubyDate.jd(2451943,24)
    assert_equal([2001, 2, 3, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.ordinal(2001,33,24)
    assert_equal([2001, 2, 3, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.new(2001,2,2,24)
    assert_equal([2001, 2, 3, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
    d = RubyDate.commercial(2001,5,5,24)
    assert_equal([2001, 2, 3, 0, 0, 0, 0],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.offset])
  end

  def test_zone
    d = RubyDate.new(2001, 2, 3)
    assert_equal(Encoding::US_ASCII, d.zone.encoding)
  end

  def test_to_s
    d = RubyDate.new(2001, 2, 3)
    assert_equal(Encoding::US_ASCII, d.to_s.encoding)
    assert_equal(Encoding::US_ASCII, d.strftime.encoding)
    d = RubyDate.new(2001, 2, 3)
    assert_equal(Encoding::US_ASCII, d.to_s.encoding)
    assert_equal(Encoding::US_ASCII, d.strftime.encoding)
  end

  def test_inspect
    d = RubyDate.new(2001, 2, 3)
    assert_equal(Encoding::US_ASCII, d.inspect.encoding)
    d = RubyDate.new(2001, 2, 3)
    assert_equal(Encoding::US_ASCII, d.inspect.encoding)
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

    assert_equal(-1, RubyDate.new(-4713,11,1,RubyDate::GREGORIAN) <=> RubyDate.new(-4713,12,1,RubyDate::GREGORIAN))
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

    d = RubyDate.new(-5000,1,1,RubyDate::JULIAN)
    assert_equal([-5000, 1, 1, 5], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5001, 11, 22, 5], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.new(-5000,1,1,RubyDate::GREGORIAN)
    assert_equal([-5000, 1, 1, 3], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([-5000, 2, 10, 3], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(-105192)
    assert_equal([-5000, 1, 1, 5], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5001, 11, 22, 5], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(-105192,RubyDate::JULIAN)
    assert_equal([-5000, 1, 1, 5], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5001, 11, 22, 5], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(-105152,RubyDate::GREGORIAN)
    assert_equal([-5000, 1, 1, 3], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([-5000, 2, 10, 3], [d2.year, d2.mon, d2.mday, d.wday])

    # -5000000
    d = RubyDate.new(-5_000_000,1,1)
    assert_equal([-5_000_000, 1, 1, 3], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5_000_103, 4, 28, 3], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.new(-5_000_000,1,1,RubyDate::JULIAN)
    assert_equal([-5_000_000, 1, 1, 3], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5_000_103, 4, 28, 3], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.new(-5_000_000,1,1,RubyDate::GREGORIAN)
    assert_equal([-5_000_000, 1, 1, 6], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([-4_999_898, 9, 4, 6], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(-1824528942)
    assert_equal([-5_000_000, 1, 1, 3], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5_000_103, 4, 28, 3], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(-1824528942,RubyDate::JULIAN)
    assert_equal([-5_000_000, 1, 1, 3], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([-5_000_103, 4, 28, 3], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(-1824491440,RubyDate::GREGORIAN)
    assert_equal([-5_000_000, 1, 1, 6], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([-4_999_898, 9, 4, 6], [d2.year, d2.mon, d2.mday, d.wday])

    # 5000000
    d = RubyDate.new(5_000_000,1,1)
    assert_equal([5_000_000, 1, 1, 6], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([4_999_897, 5, 3, 6], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.new(5_000_000,1,1,RubyDate::JULIAN)
    assert_equal([5_000_000, 1, 1, 5], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([5_000_102, 9, 1, 5], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.new(5_000_000,1,1,RubyDate::GREGORIAN)
    assert_equal([5_000_000, 1, 1, 6], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([4_999_897, 5, 3, 6], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(1827933560)
    assert_equal([5_000_000, 1, 1, 6], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([4_999_897, 5, 3, 6], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(1827971058,RubyDate::JULIAN)
    assert_equal([5_000_000, 1, 1, 5], [d.year, d.mon, d.mday, d.wday])
    d2 = d.gregorian
    assert_equal([5_000_102, 9, 1, 5], [d2.year, d2.mon, d2.mday, d.wday])

    d = RubyDate.jd(1827933560,RubyDate::GREGORIAN)
    assert_equal([5_000_000, 1, 1, 6], [d.year, d.mon, d.mday, d.wday])
    d2 = d.julian
    assert_equal([4_999_897, 5, 3, 6], [d2.year, d2.mon, d2.mday, d.wday])

    # dt
    d = RubyDate.new(-123456789,2,3,4,5,6,0)
    assert_equal([-123456789, 2, 3, 4, 5, 6, 1],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.wday])
    d2 = d.gregorian
    assert_equal([-123459325, 12, 27, 4, 5, 6, 1],
		 [d2.year, d2.mon, d2.mday, d2.hour, d2.min, d2.sec, d.wday])

    d = RubyDate.new(123456789,2,3,4,5,6,0)
    assert_equal([123456789, 2, 3, 4, 5, 6, 5],
		 [d.year, d.mon, d.mday, d.hour, d.min, d.sec, d.wday])
    d2 = d.julian
    assert_equal([123454254, 1, 19, 4, 5, 6, 5],
		 [d2.year, d2.mon, d2.mday, d2.hour, d2.min, d2.sec, d.wday])
  end

  def period2_iter2(from, to, sg)
    (from..to).each do |j|
      d = RubyDate.jd(j, sg)
      d2 = RubyDate.new(d.year, d.mon, d.mday, sg)
      assert_equal(d2.jd, j)
      assert_equal(d2.ajd, d.ajd)
      assert_equal(d2.year, d.year)

      d = RubyDate.jd(j, 12,0,0, '+12:00', sg)
      d2 = RubyDate.new(d.year, d.mon, d.mday,
			d.hour, d.min, d.sec, d.offset, sg)
      assert_equal(d2.jd, j)
      assert_equal(d2.ajd, d.ajd)
      assert_equal(d2.year, d.year)
    end
  end

  def period2_iter(from, to)
    period2_iter2(from, to, RubyDate::GREGORIAN)
    period2_iter2(from, to, RubyDate::ITALY)
    period2_iter2(from, to, RubyDate::ENGLAND)
    period2_iter2(from, to, RubyDate::JULIAN)
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
    assert_equal(0, RubyDate.jd(0) <=> RubyDate.civil(-4713, 11, 24, RubyDate::GREGORIAN))
    assert_equal(0, RubyDate.jd(213447717) <=> RubyDate.civil(579687, 11, 24))
    assert_equal(0, RubyDate.jd(-213447717) <=> RubyDate.civil(-589113, 11, 24, RubyDate::GREGORIAN))

    assert_equal(0, RubyDate.jd(0) <=> RubyDate.civil(-4713, 11, 24, 0, 0, 0, 0, RubyDate::GREGORIAN))
    assert_equal(0, RubyDate.jd(213447717) <=> RubyDate.civil(579687, 11, 24))
    assert_equal(0, RubyDate.jd(-213447717) <=> RubyDate.civil(-589113, 11, 24, 0, 0, 0, 0, RubyDate::GREGORIAN))

    assert(RubyDate.jd(0) == RubyDate.civil(-4713, 11, 24, RubyDate::GREGORIAN))
    assert(RubyDate.jd(213447717) == RubyDate.civil(579687, 11, 24))
    assert(RubyDate.jd(-213447717) == RubyDate.civil(-589113, 11, 24, RubyDate::GREGORIAN))

    assert(RubyDate.jd(0) == RubyDate.civil(-4713, 11, 24, 0, 0, 0, 0, RubyDate::GREGORIAN))
    assert(RubyDate.jd(213447717) == RubyDate.civil(579687, 11, 24))
    assert(RubyDate.jd(-213447717) == RubyDate.civil(-589113, 11, 24, 0, 0, 0, 0, RubyDate::GREGORIAN))

    assert(RubyDate.jd(0) === RubyDate.civil(-4713, 11, 24, RubyDate::GREGORIAN))
    assert(RubyDate.jd(213447717) === RubyDate.civil(579687, 11, 24))
    assert(RubyDate.jd(-213447717) === RubyDate.civil(-589113, 11, 24, RubyDate::GREGORIAN))

    assert(RubyDate.jd(0) === RubyDate.civil(-4713, 11, 24, 12, 0, 0, 0, RubyDate::GREGORIAN))
    assert(RubyDate.jd(213447717) === RubyDate.civil(579687, 11, 24, 12))
    assert(RubyDate.jd(-213447717) === RubyDate.civil(-589113, 11, 24, 12, 0, 0, 0, RubyDate::GREGORIAN))

    a = RubyDate.jd(0)
    b = RubyDate.civil(-4713, 11, 24, RubyDate::GREGORIAN)
    assert_equal(0, a <=> b)

    a = RubyDate.civil(-4712, 1, 1, RubyDate::JULIAN)
    b = RubyDate.civil(-4713, 11, 24, RubyDate::GREGORIAN)
    a.jd; b.jd
    assert_equal(0, a <=> b)

    a = RubyDate.jd(0)
    b = RubyDate.civil(-4713, 11, 24, RubyDate::GREGORIAN)
    assert(a == b)

    a = RubyDate.civil(-4712, 1, 1, RubyDate::JULIAN)
    b = RubyDate.civil(-4713, 11, 24, RubyDate::GREGORIAN)
    a.jd; b.jd
    assert(a == b)

    a = RubyDate.jd(0)
    b = RubyDate.civil(-4713, 11, 24, RubyDate::GREGORIAN)
    assert(a === b)

    a = RubyDate.civil(-4712, 1, 1, RubyDate::JULIAN)
    b = RubyDate.civil(-4713, 11, 24, RubyDate::GREGORIAN)
    a.jd; b.jd
    assert(a === b)
  end

  def test_marshal14
    s = "\x04\x03u:\x01\x04Date\x01\v\x04\x03[\x01\x02i\x03\xE8i%T"
    d = suppress_warning {Marshal.load(s)}
    assert_equal(Rational(4903887,2), d.ajd)
    assert_equal(RubyDate::GREGORIAN, d.start)
  end

  def test_marshal16
    s = "\x04\x06u:\tDate\x0F\x04\x06[\ai\x03\xE8i%T"
    d = suppress_warning {Marshal.load(s)}
    assert_equal(Rational(4903887,2), d.ajd)
    assert_equal(RubyDate::GREGORIAN, d.start)
  end

  def test_marshal18
    s = "\x04\bu:\tDateP\x04\b[\bo:\rRational\a:\x0F@numeratori\x03\xCF\xD3J:\x11@denominatori\ai\x00o:\x13RubyDate::Infinity\x06:\a@di\xFA"
    d = Marshal.load(s)
    assert_equal(Rational(4903887,2), d.ajd)
    assert_equal(RubyDate::GREGORIAN, d.start)

    s = "\x04\bu:\rDateTime`\x04\b[\bo:\rRational\a:\x0F@numeratorl+\b\xC9\xB0\x81\xBD\x02\x00:\x11@denominatori\x02\xC0\x12o;\x00\a;\x06i\b;\ai\ro:\x13RubyDate::Infinity\x06:\a@di\xFA"
    d = Marshal.load(s)
    assert_equal(Rational(11769327817,4800), d.ajd)
    assert_equal(Rational(9,24), d.offset)
    assert_equal(RubyDate::GREGORIAN, d.start)
  end

  def test_marshal192
    s = "\x04\bU:\tDate[\bU:\rRational[\ai\x03\xCF\xD3Ji\ai\x00o:\x13RubyDate::Infinity\x06:\a@di\xFA"
    d = Marshal.load(s)
    assert_equal(Rational(4903887,2), d.ajd)
    assert_equal(RubyDate::GREGORIAN, d.start)

    s = "\x04\bU:\rDateTime[\bU:\rRational[\al+\b\xC9\xB0\x81\xBD\x02\x00i\x02\xC0\x12U;\x06[\ai\bi\ro:\x13RubyDate::Infinity\x06:\a@di\xFA"
    d = Marshal.load(s)
    assert_equal(Rational(11769327817,4800), d.ajd)
    assert_equal(Rational(9,24), d.offset)
    assert_equal(RubyDate::GREGORIAN, d.start)
  end

  def test_enc
    RubyDate::MONTHNAMES.each do |s|
      assert_equal(Encoding::US_ASCII, s.encoding) if s
    end
    RubyDate::DAYNAMES.each do |s|
      assert_equal(Encoding::US_ASCII, s.encoding) if s
    end
    RubyDate::ABBR_MONTHNAMES.each do |s|
      assert_equal(Encoding::US_ASCII, s.encoding) if s
    end
    RubyDate::ABBR_DAYNAMES.each do |s|
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

    s = RubyDate.now.strftime('super $record'.dup.force_encoding('euc-jp'))
    assert_equal(Encoding::EUC_JP, s.encoding)
    s = RubyDate.now.strftime('super $record'.dup.force_encoding('ascii-8bit'))
    assert_equal(Encoding::ASCII_8BIT, s.encoding)
  end

  def test_dup
    d = RubyDate.new(2001,2,3)
    d2 = d.dup
    assert_not_equal(d.object_id, d2.object_id)
    assert_kind_of(RubyDate, d2)
    assert_equal(d, d2)

    d = RubyDate.new(2001,2,3)
    d2 = d.dup
    assert_not_equal(d.object_id, d2.object_id)
    assert_kind_of(RubyDate, d2)
    assert_equal(d, d2)
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
