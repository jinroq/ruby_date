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

  # RubyDate.new tests
  sub_test_case "RubyDate.new" do
    test "creates date with year, month, day" do
      date = RubyDate.new(2001, 2, 3)
      assert_equal(2001, date.year)
      assert_equal(2, date.month)
      assert_equal(3, date.day)
    end

    test "creates date with year only" do
      date = RubyDate.new(2022)
      assert_equal(2022, date.year)
      assert_equal(1, date.month)
      assert_equal(1, date.day)
    end

    test "creates date with year and month" do
      date = RubyDate.new(2022, 2)
      assert_equal(2022, date.year)
      assert_equal(2, date.month)
      assert_equal(1, date.day)
    end

    test "raises ArgumentError for invalid date" do
      assert_raise(ArgumentError) do
        RubyDate.new(2001, 2, 29) # 2001 is not a leap year
      end
    end

    test "raises TypeError for non-numeric year" do
      assert_raise(TypeError) do
        RubyDate.new("2001", 2, 3)
      end
    end

    test "raises TypeError for non-numeric month" do
      assert_raise(TypeError) do
        RubyDate.new(2001, "2", 3)
      end
    end

    test "raises TypeError for non-numeric day" do
      assert_raise(TypeError) do
        RubyDate.new(2001, 2, "3")
      end
    end

    test "creates leap year date" do
      date = RubyDate.new(2000, 2, 29)
      assert_equal(2000, date.year)
      assert_equal(2, date.month)
      assert_equal(29, date.day)
    end

    test "creates date in different years" do
      date = RubyDate.new(1999, 12, 31)
      assert_equal(1999, date.year)
      assert_equal(12, date.month)
      assert_equal(31, date.day)
    end

    test "handles negative day counting from end of month" do
      # Last day of February in non-leap year
      date = RubyDate.new(2001, 2, -1)
      assert_equal(2001, date.year)
      assert_equal(2, date.month)
      assert_equal(28, date.day)
    end

    test "handles negative day in leap year" do
      # Last day of February in leap year
      date = RubyDate.new(2000, 2, -1)
      assert_equal(2000, date.year)
      assert_equal(2, date.month)
      assert_equal(29, date.day)
    end

    test "creates dates across different centuries" do
      # 19th century
      d1 = RubyDate.new(1800, 1, 1)
      assert_equal(1800, d1.year)

      # 20th century
      d2 = RubyDate.new(1900, 1, 1)
      assert_equal(1900, d2.year)

      # 21st century
      d3 = RubyDate.new(2000, 1, 1)
      assert_equal(2000, d3.year)

      # 22nd century
      d4 = RubyDate.new(2100, 1, 1)
      assert_equal(2100, d4.year)
    end

    test "new with different start dates" do
      d1 = RubyDate.new(2001, 2, 3, RubyDate::ITALY)
      d2 = RubyDate.new(2001, 2, 3, RubyDate::ENGLAND)
      d3 = RubyDate.new(2001, 2, 3, RubyDate::GREGORIAN)

      # All should have same civil date
      assert_equal(d1.year, d2.year)
      assert_equal(d1.month, d2.month)
      assert_equal(d1.day, d2.day)

      # But different start values
      assert_equal(RubyDate::ITALY, d1.start)
      assert_equal(RubyDate::ENGLAND, d2.start)
      assert_equal(RubyDate::GREGORIAN, d3.start)
    end

    test "creates dates at month boundaries" do
      # January 31
      d1 = RubyDate.new(2001, 1, 31)
      assert_equal(1, d1.month)
      assert_equal(31, d1.day)

      # March 31
      d2 = RubyDate.new(2001, 3, 31)
      assert_equal(3, d2.month)
      assert_equal(31, d2.day)

      # April 30 (no 31st day)
      d3 = RubyDate.new(2001, 4, 30)
      assert_equal(4, d3.month)
      assert_equal(30, d3.day)
    end

    test "raises ArgumentError for invalid month/day combinations" do
      # February 30 doesn't exist
      assert_raise(ArgumentError) do
        RubyDate.new(2001, 2, 30)
      end

      # April 31 doesn't exist
      assert_raise(ArgumentError) do
        RubyDate.new(2001, 4, 31)
      end

      # Month 13 doesn't exist
      assert_raise(ArgumentError) do
        RubyDate.new(2001, 13, 1)
      end

      # Month 0 doesn't exist
      assert_raise(ArgumentError) do
        RubyDate.new(2001, 0, 1)
      end
    end
  end

  # RubyDate.julian_leap? tests
  sub_test_case "RubyDate.julian_leap?" do
    test "returns true for year divisible by 4" do
      assert_true(RubyDate.julian_leap?(1900))
      assert_true(RubyDate.julian_leap?(2000))
      assert_true(RubyDate.julian_leap?(2004))
    end

    test "returns false for non-leap year" do
      assert_false(RubyDate.julian_leap?(2001))
      assert_false(RubyDate.julian_leap?(2019))
      assert_false(RubyDate.julian_leap?(1901))
    end
  end

  # RubyDate.valid_civil? tests
  sub_test_case "RubyDate.valid_civil?" do
    test "returns true for valid dates" do
      assert_true(RubyDate.valid_civil?(2001, 2, 3))
      assert_true(RubyDate.valid_civil?(2000, 1, 1))
      assert_true(RubyDate.valid_civil?(2000, 12, 31))
    end

    test "returns false for invalid month" do
      assert_false(RubyDate.valid_civil?(2001, 0, 1))
      assert_false(RubyDate.valid_civil?(2001, 13, 1))
      assert_false(RubyDate.valid_civil?(2001, -1, 1))
    end

    test "returns false for invalid day" do
      assert_false(RubyDate.valid_civil?(2001, 2, 0))
      assert_false(RubyDate.valid_civil?(2001, 2, 29)) # not a leap year
      assert_false(RubyDate.valid_civil?(2001, 4, 31)) # April has 30 days
    end

    test "returns true for leap year Feb 29" do
      assert_true(RubyDate.valid_civil?(2000, 2, 29))
      assert_true(RubyDate.valid_civil?(2004, 2, 29))
    end

    test "returns false for non-leap year Feb 29" do
      assert_false(RubyDate.valid_civil?(2001, 2, 29))
      assert_false(RubyDate.valid_civil?(1900, 2, 29)) # not a leap year
    end

    test "returns true for leap year century" do
      # 2000 is divisible by 400
      assert_true(RubyDate.valid_civil?(2000, 2, 29))
    end

    test "returns false for non-leap year century" do
      # 1900 is divisible by 100 but not 400
      assert_false(RubyDate.valid_civil?(1900, 2, 29))
    end

    test "handles all months correctly" do
      # 31-day months
      assert_true(RubyDate.valid_civil?(2001, 1, 31))
      assert_true(RubyDate.valid_civil?(2001, 3, 31))
      assert_true(RubyDate.valid_civil?(2001, 5, 31))
      assert_true(RubyDate.valid_civil?(2001, 7, 31))
      assert_true(RubyDate.valid_civil?(2001, 8, 31))
      assert_true(RubyDate.valid_civil?(2001, 10, 31))
      assert_true(RubyDate.valid_civil?(2001, 12, 31))

      # 30-day months
      assert_true(RubyDate.valid_civil?(2001, 4, 30))
      assert_true(RubyDate.valid_civil?(2001, 6, 30))
      assert_true(RubyDate.valid_civil?(2001, 9, 30))
      assert_true(RubyDate.valid_civil?(2001, 11, 30))

      assert_false(RubyDate.valid_civil?(2001, 4, 31))
      assert_false(RubyDate.valid_civil?(2001, 6, 31))
      assert_false(RubyDate.valid_civil?(2001, 9, 31))
      assert_false(RubyDate.valid_civil?(2001, 11, 31))
    end

    test "returns false for non-numeric arguments" do
      assert_false(RubyDate.valid_civil?("2001", 2, 3))
      assert_false(RubyDate.valid_civil?(2001, "2", 3))
      assert_false(RubyDate.valid_civil?(2001, 2, "3"))
      assert_false(RubyDate.valid_civil?(nil, 2, 3))
    end

    test "accepts objects with to_int" do
      year_obj = Object.new
      def year_obj.to_int; 2001; end

      month_obj = Object.new
      def month_obj.to_int; 2; end

      day_obj = Object.new
      def day_obj.to_int; 3; end

      assert_true(RubyDate.valid_civil?(year_obj, month_obj, day_obj))
    end

    test "handles negative years" do
      assert_true(RubyDate.valid_civil?(-100, 1, 1))
      assert_true(RubyDate.valid_civil?(-4, 2, 29)) # leap year
      assert_false(RubyDate.valid_civil?(-3, 2, 29)) # not a leap year
    end

    test "works with different start dates" do
      assert_true(RubyDate.valid_civil?(2001, 2, 3, RubyDate::ITALY))
      assert_true(RubyDate.valid_civil?(2001, 2, 3, RubyDate::ENGLAND))
      assert_true(RubyDate.valid_civil?(2001, 2, 3, RubyDate::GREGORIAN))
      assert_true(RubyDate.valid_civil?(2001, 2, 3, RubyDate::JULIAN))
    end

    test "edge case: year 0" do
      # Year 0 exists in astronomical year numbering
      assert_true(RubyDate.valid_civil?(0, 1, 1))
    end
  end

  # RubyDate.valid_ordinal? tests
  sub_test_case "RubyDate.valid_ordinal?" do
    test "returns true for valid day in non-leap year" do
      assert_true(RubyDate.valid_ordinal?(2001, 1))
      assert_true(RubyDate.valid_ordinal?(2001, 100))
      assert_true(RubyDate.valid_ordinal?(2001, 365))
    end

    test "returns false for day 366 in non-leap year" do
      assert_false(RubyDate.valid_ordinal?(2001, 366))
    end

    test "returns true for valid day in leap year" do
      assert_true(RubyDate.valid_ordinal?(2000, 1))
      assert_true(RubyDate.valid_ordinal?(2000, 100))
      assert_true(RubyDate.valid_ordinal?(2000, 365))
      assert_true(RubyDate.valid_ordinal?(2000, 366))
    end

    test "returns false for day 367 in leap year" do
      assert_false(RubyDate.valid_ordinal?(2000, 367))
    end

    test "returns false for day 0" do
      assert_false(RubyDate.valid_ordinal?(2001, 0))
    end

    test "returns false for negative day" do
      assert_false(RubyDate.valid_ordinal?(2001, -1))
    end

    test "returns false for year 0" do
      assert_false(RubyDate.valid_ordinal?(0, 1))
    end

    test "handles negative years" do
      # Year -4 (5 BCE) is a leap year
      assert_true(RubyDate.valid_ordinal?(-4, 366))
      assert_false(RubyDate.valid_ordinal?(-4, 367))

      # Year -3 (4 BCE) is not a leap year
      assert_true(RubyDate.valid_ordinal?(-3, 365))
      assert_false(RubyDate.valid_ordinal?(-3, 366))
    end

    test "returns false for non-numeric year" do
      assert_false(RubyDate.valid_ordinal?("2001", 1))
      assert_false(RubyDate.valid_ordinal?(nil, 1))
    end

    test "returns false for non-numeric day" do
      assert_false(RubyDate.valid_ordinal?(2001, "1"))
      assert_false(RubyDate.valid_ordinal?(2001, nil))
    end

    test "accepts objects with to_int" do
      year_obj = Object.new
      def year_obj.to_int; 2001; end

      day_obj = Object.new
      def day_obj.to_int; 100; end

      assert_true(RubyDate.valid_ordinal?(year_obj, day_obj))
    end

    test "works with different start dates" do
      # Should work with ITALY, ENGLAND, GREGORIAN, JULIAN
      assert_true(RubyDate.valid_ordinal?(2000, 366, RubyDate::ITALY))
      assert_true(RubyDate.valid_ordinal?(2000, 366, RubyDate::ENGLAND))
      assert_true(RubyDate.valid_ordinal?(2000, 366, RubyDate::GREGORIAN))
      assert_true(RubyDate.valid_ordinal?(2000, 366, RubyDate::JULIAN))
    end

    test "century years leap year handling" do
      # 1900 is not a leap year in Gregorian
      assert_false(RubyDate.valid_ordinal?(1900, 366, RubyDate::GREGORIAN))
      assert_true(RubyDate.valid_ordinal?(1900, 365, RubyDate::GREGORIAN))

      # 2000 is a leap year in Gregorian
      assert_true(RubyDate.valid_ordinal?(2000, 366, RubyDate::GREGORIAN))

      # 1900 is a leap year in Julian calendar
      assert_true(RubyDate.valid_ordinal?(1900, 366, RubyDate::JULIAN))
    end

    test "boundary values" do
      # Day 1 (minimum)
      assert_true(RubyDate.valid_ordinal?(2001, 1))

      # Day 365 (maximum for non-leap year)
      assert_true(RubyDate.valid_ordinal?(2001, 365))

      # Day 366 (maximum for leap year)
      assert_true(RubyDate.valid_ordinal?(2000, 366))
    end
  end

  # RubyDate.ordinal tests
  sub_test_case "RubyDate.ordinal" do
    test "creates date from year and day of year" do
      date = RubyDate.ordinal(2001, 34)
      assert_equal(2001, date.year)
      assert_equal(2, date.month)
      assert_equal(3, date.day)
    end

    test "creates date with year only" do
      date = RubyDate.ordinal(2001)
      assert_equal(2001, date.year)
      assert_equal(1, date.month)
      assert_equal(1, date.day)
    end

    test "creates date for first day of year" do
      date = RubyDate.ordinal(2001, 1)
      assert_equal(2001, date.year)
      assert_equal(1, date.month)
      assert_equal(1, date.day)
    end

    test "creates date for last day of year (non-leap)" do
      date = RubyDate.ordinal(2001, 365)
      assert_equal(2001, date.year)
      assert_equal(12, date.month)
      assert_equal(31, date.day)
    end

    test "creates date for last day of year (leap)" do
      date = RubyDate.ordinal(2000, 366)
      assert_equal(2000, date.year)
      assert_equal(12, date.month)
      assert_equal(31, date.day)
    end

    test "handles negative day of year" do
      date = RubyDate.ordinal(2001, -14)
      assert_equal(2001, date.year)
      assert_equal(12, date.month)
      assert_equal(18, date.day)
    end

    test "handles negative day of year for first day" do
      date = RubyDate.ordinal(2001, -365)
      assert_equal(2001, date.year)
      assert_equal(1, date.month)
      assert_equal(1, date.day)
    end

    test "creates date for day 60 in leap year (Feb 29)" do
      date = RubyDate.ordinal(2000, 60)
      assert_equal(2000, date.year)
      assert_equal(2, date.month)
      assert_equal(29, date.day)
    end

    test "creates date for day 60 in non-leap year (Mar 1)" do
      date = RubyDate.ordinal(2001, 60)
      assert_equal(2001, date.year)
      assert_equal(3, date.month)
      assert_equal(1, date.day)
    end

    test "creates date for middle of year" do
      date = RubyDate.ordinal(2001, 182)
      assert_equal(2001, date.year)
      assert_equal(7, date.month)
      assert_equal(1, date.day)
    end

    test "ordinal raises TypeError for non-numeric year" do
      assert_raise(TypeError) do
        RubyDate.ordinal("2001", 34)
      end
    end

    test "ordinal raises TypeError for non-numeric yday" do
      assert_raise(TypeError) do
        RubyDate.ordinal(2001, "34")
      end
    end

    test "raises ArgumentError for invalid day of year" do
      assert_raise(ArgumentError) do
        RubyDate.ordinal(2001, 366) # 2001 is not a leap year
      end
    end

    test "raises ArgumentError for zero day of year" do
      assert_raise(ArgumentError) do
        RubyDate.ordinal(2001, 0)
      end
    end

    test "raises ArgumentError for day of year too large" do
      assert_raise(ArgumentError) do
        RubyDate.ordinal(2000, 367) # even leap year only has 366 days
      end
    end

    test "ordinal with fractional yday" do
      date = RubyDate.ordinal(2001, 34.5)
      assert_equal(2001, date.year)
      assert_equal(2, date.month)
      assert_equal(4, date.day)
    end

    test "ordinal with Rational yday" do
      date = RubyDate.ordinal(2001, Rational(69, 2))
      assert_equal(2001, date.year)
      assert_equal(2, date.month)
      assert_equal(4, date.day)
    end

    test "ordinal dates match regular dates" do
      d1 = RubyDate.ordinal(2001, 34)
      d2 = RubyDate.new(2001, 2, 3)
      assert_equal(d1, d2)
      assert_equal(d1.jd, d2.jd)
    end

    test "ordinal consecutive days" do
      d1 = RubyDate.ordinal(2001, 100)
      d2 = RubyDate.ordinal(2001, 101)
      assert_equal(1, d2.jd - d1.jd)
    end

    test "ordinal across different years" do
      dates = [
        [1999, 365, 1999, 12, 31],
        [2000, 1, 2000, 1, 1],
        [2000, 366, 2000, 12, 31],
        [2024, 366, 2024, 12, 31],
      ]

      dates.each do |year, yday, exp_year, exp_month, exp_day|
        date = RubyDate.ordinal(year, yday)
        assert_equal(exp_year, date.year, "Year mismatch for #{year}-#{yday}")
        assert_equal(exp_month, date.month, "Month mismatch for #{year}-#{yday}")
        assert_equal(exp_day, date.day, "Day mismatch for #{year}-#{yday}")
      end
    end

    test "ordinal with various negative values" do
      # Last day of year
      d1 = RubyDate.ordinal(2001, -1)
      assert_equal(2001, d1.year)
      assert_equal(12, d1.month)
      assert_equal(31, d1.day)

      # Second to last day
      d2 = RubyDate.ordinal(2001, -2)
      assert_equal(2001, d2.year)
      assert_equal(12, d2.month)
      assert_equal(30, d2.day)
    end

    test "ordinal leap year edge cases" do
      # Feb 28 in leap year (day 59)
      d1 = RubyDate.ordinal(2000, 59)
      assert_equal(2000, d1.year)
      assert_equal(2, d1.month)
      assert_equal(28, d1.day)

      # Feb 29 in leap year (day 60)
      d2 = RubyDate.ordinal(2000, 60)
      assert_equal(2000, d2.year)
      assert_equal(2, d2.month)
      assert_equal(29, d2.day)

      # Mar 1 in leap year (day 61)
      d3 = RubyDate.ordinal(2000, 61)
      assert_equal(2000, d3.year)
      assert_equal(3, d3.month)
      assert_equal(1, d3.day)
    end

    test "ordinal with different start dates" do
      # Should work with different calendar reform dates
      d1 = RubyDate.ordinal(2001, 100, RubyDate::ITALY)
      d2 = RubyDate.ordinal(2001, 100, RubyDate::ENGLAND)

      # Same year and yday should give same result regardless of start
      assert_equal(d1.year, d2.year)
      assert_equal(d1.month, d2.month)
      assert_equal(d1.day, d2.day)
    end

    test "ordinal uses valid_ordinal? for validation" do
      # Valid ordinal dates should be creatable
      assert_nothing_raised do
        RubyDate.ordinal(2000, 366)
      end

      # Invalid ordinal dates should raise ArgumentError
      assert_raise(ArgumentError) do
        RubyDate.ordinal(2001, 366)
      end

      assert_raise(ArgumentError) do
        RubyDate.ordinal(2001, 0)
      end
    end
  end

  # Comparison and equality tests
  sub_test_case "comparison and equality" do
    test "spaceship operator compares dates" do
      d1 = RubyDate.new(2001, 2, 3)
      d2 = RubyDate.new(2001, 2, 4)
      d3 = RubyDate.new(2001, 2, 3)

      assert_equal(-1, d1 <=> d2)
      assert_equal(1, d2 <=> d1)
      assert_equal(0, d1 <=> d3)
    end

    test "spaceship operator returns nil for non-date" do
      d1 = RubyDate.new(2001, 2, 3)
      assert_nil(d1 <=> "not a date")
    end

    test "== compares dates for equality" do
      d1 = RubyDate.new(2001, 2, 3)
      d2 = RubyDate.new(2001, 2, 3)
      d3 = RubyDate.new(2001, 2, 4)

      assert_true(d1 == d2)
      assert_false(d1 == d3)
      assert_false(d1 == "not a date")
    end

    test "eql? compares dates including start value" do
      d1 = RubyDate.new(2001, 2, 3, RubyDate::ITALY)
      d2 = RubyDate.new(2001, 2, 3, RubyDate::ITALY)
      d3 = RubyDate.new(2001, 2, 3, RubyDate::ENGLAND)

      assert_true(d1.eql?(d2))
      assert_false(d1.eql?(d3))
      assert_false(d1.eql?("not a date"))
    end

    test "hash returns consistent hash value" do
      d1 = RubyDate.new(2001, 2, 3)
      d2 = RubyDate.new(2001, 2, 3)

      assert_equal(d1.hash, d2.hash)
    end

    test "less than comparison" do
      d1 = RubyDate.new(2001, 2, 3)
      d2 = RubyDate.new(2001, 2, 4)

      assert_true(d1 < d2)
      assert_false(d2 < d1)
    end

    test "greater than comparison" do
      d1 = RubyDate.new(2001, 2, 3)
      d2 = RubyDate.new(2001, 2, 4)

      assert_true(d2 > d1)
      assert_false(d1 > d2)
    end
  end

  # Date arithmetic tests
  sub_test_case "date arithmetic" do
    test "adds integer days to date" do
      d = RubyDate.new(2001, 2, 3)
      d2 = d + 1

      assert_equal(2001, d2.year)
      assert_equal(2, d2.month)
      assert_equal(4, d2.day)
    end

    test "adds multiple days to date" do
      d = RubyDate.new(2001, 2, 3)
      d2 = d + 10

      assert_equal(2001, d2.year)
      assert_equal(2, d2.month)
      assert_equal(13, d2.day)
    end

    test "adding zero returns same date" do
      d = RubyDate.new(2001, 2, 3)
      d2 = d + 0

      assert_equal(d.year, d2.year)
      assert_equal(d.month, d2.month)
      assert_equal(d.day, d2.day)
    end

    test "adds days across month boundary" do
      d = RubyDate.new(2001, 2, 28)
      d2 = d + 1

      assert_equal(2001, d2.year)
      assert_equal(3, d2.month)
      assert_equal(1, d2.day)
    end

    test "adds days across year boundary" do
      d = RubyDate.new(2001, 12, 31)
      d2 = d + 1

      assert_equal(2002, d2.year)
      assert_equal(1, d2.month)
      assert_equal(1, d2.day)
    end

    test "adds fractional days" do
      d = RubyDate.new(2001, 2, 3)
      d2 = d + 0.5

      assert_equal(2001, d2.year)
      assert_equal(2, d2.month)
      assert_equal(4, d2.day)
    end

    test "adds Rational days" do
      d = RubyDate.new(2001, 2, 3)
      d2 = d + Rational(1, 2)

      assert_equal(2001, d2.year)
      assert_equal(2, d2.month)
      assert_equal(4, d2.day)
    end

    test "adds large number of days" do
      d = RubyDate.new(2001, 1, 1)
      d2 = d + 365

      assert_equal(2002, d2.year)
      assert_equal(1, d2.month)
      assert_equal(1, d2.day)
    end

    test "adds days to leap year" do
      d = RubyDate.new(2000, 2, 28)
      d2 = d + 1

      assert_equal(2000, d2.year)
      assert_equal(2, d2.month)
      assert_equal(29, d2.day)
    end

    test "adds days across leap day" do
      d = RubyDate.new(2000, 2, 29)
      d2 = d + 1

      assert_equal(2000, d2.year)
      assert_equal(3, d2.month)
      assert_equal(1, d2.day)
    end

    test "adds negative fraction rounds to same day" do
      d = RubyDate.new(2001, 2, 3)
      d2 = d + (-0.5)

      assert_equal(2001, d2.year)
      assert_equal(2, d2.month)
      assert_equal(3, d2.day)
    end
  end

  # Additional jd tests with different start dates
  sub_test_case "dates with different calendar systems" do
    test "creates date with ITALY start (default)" do
      d = RubyDate.jd(2451944, RubyDate::ITALY)
      assert_equal(RubyDate::ITALY, d.start)
    end

    test "creates date with ENGLAND start" do
      d = RubyDate.jd(2451944, RubyDate::ENGLAND)
      assert_equal(RubyDate::ENGLAND, d.start)
    end

    test "creates date with JULIAN start" do
      d = RubyDate.jd(2451944, RubyDate::JULIAN)
      assert_equal(RubyDate::JULIAN, d.start)
    end

    test "creates date with GREGORIAN start" do
      d = RubyDate.jd(2451944, RubyDate::GREGORIAN)
      assert_equal(RubyDate::GREGORIAN, d.start)
    end
  end

  # Test for new with fractional values
  sub_test_case "RubyDate.new with fractional values" do
    test "creates date with fractional day" do
      date = RubyDate.new(2001, 2, 3.5)
      assert_equal(2001, date.year)
      assert_equal(2, date.month)
      assert_equal(4, date.day)
    end

    test "creates date with fractional month" do
      # Fractional month adds to the day
      date = RubyDate.new(2001, 2.5, 3)
      assert_equal(2001, date.year)
      assert_equal(2, date.month)
      assert_equal(4, date.day)
    end
  end

  # Edge cases and boundary tests
  sub_test_case "edge cases" do
    test "handles very large JD numbers" do
      large_jd = 10000000
      date = RubyDate.jd(large_jd)
      assert_equal(large_jd, date.jd)
    end

    test "handles negative JD numbers" do
      negative_jd = -1000
      date = RubyDate.jd(negative_jd)
      assert_equal(negative_jd, date.jd)
    end

    test "consecutive dates have consecutive JDs" do
      d1 = RubyDate.new(2001, 2, 3)
      d2 = RubyDate.new(2001, 2, 4)
      assert_equal(1, d2.jd - d1.jd)
    end

    test "dates around reform date" do
      # Date just before ITALY reform
      d1 = RubyDate.jd(RubyDate::ITALY - 1)
      # Date at ITALY reform
      d2 = RubyDate.jd(RubyDate::ITALY)

      assert_equal(1, d2.jd - d1.jd)
    end
  end

  # RubyDate.commercial tests (ISO week date)
  sub_test_case "RubyDate.commercial" do
    test "creates date from ISO week date" do
      # 2001-W05-6 = 2001-02-03 (Saturday)
      date = RubyDate.commercial(2001, 5, 6)
      assert_equal(2001, date.year)
      assert_equal(2, date.month)
      assert_equal(3, date.day)
    end

    test "creates date for first week Monday" do
      # 2022-W01-1 = 2022-01-03 (Monday)
      date = RubyDate.commercial(2022, 1, 1)
      assert_equal(2022, date.year)
      assert_equal(1, date.month)
      assert_equal(3, date.day)
    end

    test "creates date for last week of year" do
      # 2022-W52-1 = 2022-12-26 (Monday)
      date = RubyDate.commercial(2022, 52, 1)
      assert_equal(2022, date.year)
      assert_equal(12, date.month)
      assert_equal(26, date.day)
    end

    test "handles negative week" do
      # Last week of the year
      date = RubyDate.commercial(2022, -1, 1)
      assert_equal(2022, date.year)
      assert_equal(12, date.month)
      assert_equal(26, date.day)
    end

    test "handles negative weekday" do
      # -7 is Monday (same as 1)
      date = RubyDate.commercial(2022, 1, -7)
      assert_equal(2022, date.year)
      assert_equal(1, date.month)
      assert_equal(3, date.day)
    end

    test "week 1 contains January 4" do
      # By ISO 8601 definition, week 1 contains January 4
      # 2023: Jan 4 is Wednesday, so W01 starts on Monday Jan 2
      date = RubyDate.commercial(2023, 1, 1)
      assert_equal(2023, date.year)
      assert_equal(1, date.month)
      assert_equal(2, date.day)
    end

    test "raises TypeError for non-numeric cwyear" do
      assert_raise(TypeError) do
        RubyDate.commercial("2001", 5, 6)
      end
    end

    test "raises TypeError for non-numeric cweek" do
      assert_raise(TypeError) do
        RubyDate.commercial(2001, "5", 6)
      end
    end

    test "raises TypeError for non-numeric cwday" do
      assert_raise(TypeError) do
        RubyDate.commercial(2001, 5, "6")
      end
    end

    test "raises ArgumentError for invalid weekday" do
      assert_raise(ArgumentError) do
        RubyDate.commercial(2001, 1, 0)
      end
    end

    test "raises ArgumentError for weekday > 7" do
      assert_raise(ArgumentError) do
        RubyDate.commercial(2001, 1, 8)
      end
    end

    test "commercial with fractional values" do
      date = RubyDate.commercial(2001, 5, 6.5)
      assert_equal(2001, date.year)
      assert_equal(2, date.month)
      assert_equal(4, date.day)
    end

    test "commercial dates across year boundary" do
      # Some dates in week 1 can be in previous year
      # 2020: Jan 1 is Wednesday, so W01 starts on Mon Dec 30, 2019
      date = RubyDate.commercial(2020, 1, 1)
      assert_equal(2019, date.year)
      assert_equal(12, date.month)
      assert_equal(30, date.day)
    end
  end

  # RubyDate.today tests
  sub_test_case "RubyDate.today" do
    test "returns today's date" do
      date = RubyDate.today

      # Just check it returns a RubyDate object with reasonable values
      assert_kind_of(RubyDate, date)
      assert_kind_of(Integer, date.year)
      assert(date.year >= 2020 && date.year <= 2100)
      assert(date.month >= 1 && date.month <= 12)
      assert(date.day >= 1 && date.day <= 31)
    end

    test "today with different start dates" do
      d1 = RubyDate.today(RubyDate::ITALY)
      d2 = RubyDate.today(RubyDate::GREGORIAN)

      # Should have same civil date
      assert_equal(d1.year, d2.year)
      assert_equal(d1.month, d2.month)
      assert_equal(d1.day, d2.day)

      # But different start values
      assert_equal(RubyDate::ITALY, d1.start)
      assert_equal(RubyDate::GREGORIAN, d2.start)
    end
  end

  # Negative month and day tests
  sub_test_case "negative month and day" do
    test "handles negative month" do
      # -11 means 11 months before end of year (February)
      date = RubyDate.new(2022, -11, 4)
      assert_equal(2022, date.year)
      assert_equal(2, date.month)
      assert_equal(4, date.day)
    end

    test "handles negative day" do
      # -1 means last day of month
      date = RubyDate.new(2001, 2, -1)
      assert_equal(2001, date.year)
      assert_equal(2, date.month)
      assert_equal(28, date.day)
    end

    test "handles negative day in leap year" do
      date = RubyDate.new(2000, 2, -1)
      assert_equal(2000, date.year)
      assert_equal(2, date.month)
      assert_equal(29, date.day)
    end

    test "handles negative day in month with 31 days" do
      date = RubyDate.new(2001, 1, -1)
      assert_equal(2001, date.year)
      assert_equal(1, date.month)
      assert_equal(31, date.day)
    end

    test "handles negative day -2" do
      date = RubyDate.new(2001, 3, -2)
      assert_equal(2001, date.year)
      assert_equal(3, date.month)
      assert_equal(30, date.day)
    end
  end

  # String representation tests
  sub_test_case "string representations" do
    test "to_s returns ISO 8601 format" do
      date = RubyDate.new(2001, 2, 3)
      assert_equal("2001-02-03", date.to_s)
    end

    test "to_s with single digit month and day" do
      date = RubyDate.new(2001, 1, 5)
      assert_equal("2001-01-05", date.to_s)
    end

    test "to_s with year 0" do
      date = RubyDate.jd(1721058) # Year 0
      assert_match(/^0000-/, date.to_s)
    end

    test "inspect includes JD and start value" do
      date = RubyDate.new(2001, 2, 3)
      result = date.inspect

      assert_kind_of(String, result)
      assert_match(/RubyDate/, result)
      assert_match(/2001-02-03/, result)
      assert_match(/\d+j/, result) # JD value
    end

    test "inspect with different start dates" do
      d1 = RubyDate.new(2001, 2, 3, RubyDate::ITALY)
      d2 = RubyDate.new(2001, 2, 3, RubyDate::ENGLAND)

      # Should show different start values in inspect
      assert_not_equal(d1.inspect, d2.inspect)
    end
  end

  # Additional jd tests
  sub_test_case "jd edge cases" do
    test "jd method is consistent" do
      # Creating from JD and reading JD should be consistent
      original_jd = 2451944
      date = RubyDate.jd(original_jd)
      assert_equal(original_jd, date.jd)
    end

    test "date created from new has correct jd" do
      date = RubyDate.new(2001, 2, 3)
      # JD for 2001-02-03 is 2451944
      assert_equal(2451944, date.jd)
    end

    test "ordinal and new create same jd" do
      d1 = RubyDate.ordinal(2001, 34)
      d2 = RubyDate.new(2001, 2, 3)
      assert_equal(d1.jd, d2.jd)
    end
  end

  # Start date (calendar reform) tests
  sub_test_case "calendar reform handling" do
    test "dates with GREGORIAN start" do
      date = RubyDate.new(2001, 2, 3, RubyDate::GREGORIAN)
      assert_equal(RubyDate::GREGORIAN, date.start)
    end

    test "dates with JULIAN start" do
      date = RubyDate.new(2001, 2, 3, RubyDate::JULIAN)
      assert_equal(RubyDate::JULIAN, date.start)
    end

    test "dates with ITALY reform" do
      date = RubyDate.new(2001, 2, 3, RubyDate::ITALY)
      assert_equal(RubyDate::ITALY, date.start)
    end

    test "dates with ENGLAND reform" do
      date = RubyDate.new(2001, 2, 3, RubyDate::ENGLAND)
      assert_equal(RubyDate::ENGLAND, date.start)
    end
  end

  # Year 0 and BCE dates tests
  sub_test_case "year 0 and BCE dates" do
    test "handles year 0" do
      date = RubyDate.new(0, 1, 1)
      assert_equal(0, date.year)
      assert_equal(1, date.month)
      assert_equal(1, date.day)
    end

    test "handles negative years (BCE)" do
      date = RubyDate.new(-100, 1, 1)
      assert_equal(-100, date.year)
      assert_equal(1, date.month)
      assert_equal(1, date.day)
    end

    test "negative years leap year check" do
      # Year -4 (5 BCE) should be a leap year (divisible by 4)
      assert_true(RubyDate.julian_leap?(-4))

      # Year -1 (2 BCE) is not divisible by 4 in Ruby's modulo
      assert_false(RubyDate.julian_leap?(-1))

      # Year -8 (9 BCE) should be a leap year
      assert_true(RubyDate.julian_leap?(-8))
    end
  end

  # RubyDate.civil tests
  sub_test_case "RubyDate.civil" do
    test "civil is an alias for new" do
      d1 = RubyDate.civil(2001, 2, 3)
      d2 = RubyDate.new(2001, 2, 3)

      assert_equal(d1.year, d2.year)
      assert_equal(d1.month, d2.month)
      assert_equal(d1.day, d2.day)
      assert_equal(d1.jd, d2.jd)
    end

    test "civil accepts same arguments as new" do
      assert_nothing_raised do
        RubyDate.civil(2001, 2, 3, RubyDate::ITALY)
      end
    end
  end
end
