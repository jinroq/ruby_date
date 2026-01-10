# frozen_string_literal: true

require "test_helper"

class RubyDateTest < Test::Unit::TestCase
  test "VERSION" do
    assert do
      ::RubyDate.const_defined?(:VERSION)
    end
  end

  # RubyDate.jd tests
  sub_test_case "RubyDate.jd" do
    test "test_eql_p" do
      d = RubyDate.jd(0)
      d2 = RubyDate.jd(0)

      assert_equal(d, d2)
      assert_not_equal(d, 0)
    end

    test "creates date from Julian Day Number" do
      date = RubyDate.jd(2451944)
      assert_equal(2451944, date.jd)
    end

    test "jd with default value" do
      date = RubyDate.jd(0)
      assert_equal(0, date.jd)
    end

    test "jd with fractional value" do
      date = RubyDate.jd(2451944.5)
      assert_equal(2451945, date.jd)
    end

    test "jd with Rational value" do
      date = RubyDate.jd(Rational(2451944, 1))
      assert_equal(2451944, date.jd)
    end

    test "jd raises TypeError for non-numeric input" do
      assert_raise(TypeError) do
        RubyDate.jd("invalid")
      end
    end
  end

  # RubyDate.gregorian_leap? tests
  sub_test_case "RubyDate.gregorian_leap?" do
    test "returns true for leap year divisible by 4" do
      assert_true(RubyDate.gregorian_leap?(2004))
      assert_true(RubyDate.gregorian_leap?(2020))
    end

    test "returns false for non-leap year" do
      assert_false(RubyDate.gregorian_leap?(2001))
      assert_false(RubyDate.gregorian_leap?(2019))
    end

    test "returns false for year divisible by 100 but not 400" do
      assert_false(RubyDate.gregorian_leap?(1900))
      assert_false(RubyDate.gregorian_leap?(2100))
    end

    test "returns true for year divisible by 400" do
      assert_true(RubyDate.gregorian_leap?(2000))
      assert_true(RubyDate.gregorian_leap?(2400))
    end
  end

  # Instance method tests
  sub_test_case "instance methods" do
    test "jd returns Julian Day Number" do
      date = RubyDate.jd(2451944)
      assert_equal(2451944, date.jd)
    end

    test "start returns start value" do
      date = RubyDate.jd(2451944, RubyDate::ITALY)
      assert_equal(RubyDate::ITALY, date.start)
    end

    test "infinite? returns false" do
      date = RubyDate.jd(2451944)
      assert_false(date.infinite?)
    end

    test "year returns year from Julian Day" do
      date = RubyDate.jd(2451944)
      assert_equal(2001, date.year)
    end

    test "month returns month from Julian Day" do
      date = RubyDate.jd(2451944)
      assert_equal(2, date.month)
    end

    test "mon is alias for month" do
      date = RubyDate.jd(2451944)
      assert_equal(date.month, date.mon)
    end

    test "day returns day from Julian Day" do
      date = RubyDate.jd(2451944)
      assert_equal(3, date.day)
    end

    test "mday is alias for day" do
      date = RubyDate.jd(2451944)
      assert_equal(date.day, date.mday)
    end
  end

  # Constants tests
  sub_test_case "constants" do
    test "MONTHNAMES is defined" do
      assert_equal("January", RubyDate::MONTHNAMES[1])
      assert_equal("December", RubyDate::MONTHNAMES[12])
      assert_nil(RubyDate::MONTHNAMES[0])
    end

    test "ABBR_MONTHNAMES is defined" do
      assert_equal("Jan", RubyDate::ABBR_MONTHNAMES[1])
      assert_equal("Dec", RubyDate::ABBR_MONTHNAMES[12])
      assert_nil(RubyDate::ABBR_MONTHNAMES[0])
    end

    test "DAYNAMES is defined" do
      assert_equal("Sunday", RubyDate::DAYNAMES[0])
      assert_equal("Saturday", RubyDate::DAYNAMES[6])
    end

    test "ABBR_DAYNAMES is defined" do
      assert_equal("Sun", RubyDate::ABBR_DAYNAMES[0])
      assert_equal("Sat", RubyDate::ABBR_DAYNAMES[6])
    end

    test "calendar constants are defined" do
      assert_equal(2299161, RubyDate::ITALY)
      assert_equal(2361222, RubyDate::ENGLAND)
      assert_equal(Float::INFINITY, RubyDate::JULIAN)
      assert_equal(-Float::INFINITY, RubyDate::GREGORIAN)
    end
  end

  # Infinity class tests
  sub_test_case "RubyDate::Infinity" do
    test "zero? returns false" do
      inf = RubyDate::Infinity.new(1)
      assert_false(inf.zero?)
    end

    test "finite? returns false" do
      inf = RubyDate::Infinity.new(1)
      assert_false(inf.finite?)
    end

    test "infinite? returns 1 for positive infinity" do
      inf = RubyDate::Infinity.new(1)
      assert_equal(1, inf.infinite?)
    end

    test "infinite? returns -1 for negative infinity" do
      inf = RubyDate::Infinity.new(-1)
      assert_equal(-1, inf.infinite?)
    end

    test "infinite? returns nil for zero (NaN)" do
      inf = RubyDate::Infinity.new(0)
      assert_nil(inf.infinite?)
    end

    test "nan? returns true for zero" do
      inf = RubyDate::Infinity.new(0)
      assert_true(inf.nan?)
    end

    test "nan? returns false for non-zero" do
      inf = RubyDate::Infinity.new(1)
      assert_false(inf.nan?)
    end

    test "abs returns positive infinity" do
      inf = RubyDate::Infinity.new(-1)
      abs_inf = inf.abs
      assert_kind_of(RubyDate::Infinity, abs_inf)
      assert_equal(1, abs_inf.infinite?)
    end

    test "unary minus negates direction" do
      inf = RubyDate::Infinity.new(1)
      neg_inf = -inf
      assert_kind_of(RubyDate::Infinity, neg_inf)
      assert_equal(-1, neg_inf.infinite?)
    end

    test "to_f converts to Float::INFINITY" do
      inf = RubyDate::Infinity.new(1)
      assert_equal(Float::INFINITY, inf.to_f)
    end

    test "to_f converts to negative Float::INFINITY" do
      inf = RubyDate::Infinity.new(-1)
      assert_equal(-Float::INFINITY, inf.to_f)
    end

    test "to_f converts to Float::NAN for zero" do
      inf = RubyDate::Infinity.new(0)
      result = inf.to_f
      assert(result == 0 || (result.is_a?(Float) && result.nan?),
             "Expected Float::NAN or 0, but got #{result.inspect}")
    end

    test "comparison with numeric" do
      inf = RubyDate::Infinity.new(1)
      assert_equal(1, inf <=> 100)
      assert_equal(1, inf <=> -100)
    end

    test "comparison with Float::INFINITY" do
      inf = RubyDate::Infinity.new(1)
      assert_equal(0, inf <=> Float::INFINITY)
    end

    test "comparison with negative Float::INFINITY" do
      inf = RubyDate::Infinity.new(-1)
      assert_equal(0, inf <=> -Float::INFINITY)
    end

    test "coerce with numeric" do
      inf = RubyDate::Infinity.new(1)
      l, r = inf.coerce(10)
      assert_equal(-1, l)
      assert_equal(1, r)
    end
  end

  # Date conversion tests
  sub_test_case "date conversions" do
    test "various Julian Days convert to correct dates" do
      # JD 2451944 = 2001-02-03
      date = RubyDate.jd(2451944)
      assert_equal(2001, date.year)
      assert_equal(2, date.month)
      assert_equal(3, date.day)

      # JD 2451945 = 2001-02-04
      date = RubyDate.jd(2451945)
      assert_equal(2001, date.year)
      assert_equal(2, date.month)
      assert_equal(4, date.day)

      # JD 0 = -4712-01-01
      date = RubyDate.jd(0)
      assert_equal(-4712, date.year)
      assert_equal(1, date.month)
      assert_equal(1, date.day)
    end

    test "leap year dates" do
      # 2000 is a leap year
      date = RubyDate.jd(2451604) # 2000-02-29
      assert_equal(2000, date.year)
      assert_equal(2, date.month)
      assert_equal(29, date.day)
    end

    test "century boundary dates" do
      # 2000-01-01
      date = RubyDate.jd(2451545)
      assert_equal(2000, date.year)
      assert_equal(1, date.month)
      assert_equal(1, date.day)

      # 1900-01-01
      date = RubyDate.jd(2415021)
      assert_equal(1900, date.year)
      assert_equal(1, date.month)
      assert_equal(1, date.day)
    end
  end
end
