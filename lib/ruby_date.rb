# frozen_string_literal: true

require_relative "ruby_date/version"

class RubyDate
  include Comparable

  # Constants
  HAVE_JD     = 0b00000001  # 1
  HAVE_DF     = 0b00000010  # 2
  HAVE_CIVIL  = 0b00000100  # 4
  HAVE_TIME   = 0b00001000  # 8
  COMPLEX_DAT = 0b10000000  # 128
  private_constant :HAVE_JD, :HAVE_DF, :HAVE_CIVIL, :HAVE_TIME, :COMPLEX_DAT

  MONTHNAMES = [nil, "January", "February", "March", "April", "May", "June",
                "July", "August", "September", "October", "November", "December"].freeze
  ABBR_MONTHNAMES = [nil, "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                     "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"].freeze
  DAYNAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze
  ABBR_DAYNAMES = %w[Sun Mon Tue Wed Thu Fri Sat].freeze

  ITALY     = 2299161 # 1582-10-15
  ENGLAND   = 2361222 # 1752-09-14
  JULIAN    = Float::INFINITY
  GREGORIAN = -Float::INFINITY

  DEFAULT_SG = ITALY
  private_constant :DEFAULT_SG

  CM_PERIOD = 71149239 # (lcm 7 1461 146097)
  private_constant :CM_PERIOD

  REFORM_BEGIN_YEAR = 1582
  REFORM_END_YEAR   = 1930
  private_constant :REFORM_BEGIN_YEAR, :REFORM_END_YEAR

  # Days in each month (non-leap and leap year)
  MONTH_DAYS = [
    [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],  # non-leap
    [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]   # leap
  ].freeze
  private_constant :MONTH_DAYS

  # Neri-Schneider algorithm constants
  # JDN of March 1, Year 0 in proleptic Gregorian calendar
  NS_EPOCH = 1721120
  private_constant :NS_EPOCH

  # Days in a 4-year cycle (3 normal years + 1 leap year)
  NS_DAYS_IN_4_YEARS = 1461
  private_constant :NS_DAYS_IN_4_YEARS

  # Days in a 400-year Gregorian cycle (97 leap years in 400 years)
  NS_DAYS_IN_400_YEARS = 146097
  private_constant :NS_DAYS_IN_400_YEARS

  # Years per century
  NS_YEARS_PER_CENTURY = 100
  private_constant :NS_YEARS_PER_CENTURY

  # Multiplier for extracting year within century using fixed-point arithmetic.
  # This is ceil(2^32 / NS_DAYS_IN_4_YEARS) for the Euclidean affine function.
  NS_YEAR_MULTIPLIER = 2939745
  private_constant :NS_YEAR_MULTIPLIER

  # Coefficients for month calculation from day-of-year.
  # Maps day-of-year to month using: month = (NS_MONTH_COEFF * doy + NS_MONTH_OFFSET) >> 16
  NS_MONTH_COEFF  = 2141
  NS_MONTH_OFFSET = 197913
  private_constant :NS_MONTH_COEFF, :NS_MONTH_OFFSET

  # Coefficients for civil date to JDN month contribution.
  # Maps month to accumulated days: days = (NS_CIVIL_MONTH_COEFF * m - NS_CIVIL_MONTH_OFFSET) / 32
  NS_CIVIL_MONTH_COEFF   = 979
  NS_CIVIL_MONTH_OFFSET  = 2919
  NS_CIVIL_MONTH_DIVISOR = 32
  private_constant :NS_CIVIL_MONTH_COEFF, :NS_CIVIL_MONTH_OFFSET, :NS_CIVIL_MONTH_DIVISOR

  # Days from March 1 to December 31 (for Jan/Feb year adjustment)
  NS_DAYS_BEFORE_NEW_YEAR = 306
  private_constant :NS_DAYS_BEFORE_NEW_YEAR

  # Safe bounds for Neri-Schneider algorithm to avoid integer overflow.
  # These correspond to approximately years -1,000,000 to +1,000,000.
  NS_JD_MIN = -364_000_000
  NS_JD_MAX = 538_000_000
  private_constant :NS_JD_MIN, :NS_JD_MAX

  # Initialize method
  # call-seq:
  #   Date.new(year = -4712, month = 1, mday = 1, start = Date::ITALY) -> date
  #
  # Returns a new Date object constructed from the given arguments:
  #
  #   Date.new(2022).to_s        # => "2022-01-01"
  #   Date.new(2022, 2).to_s     # => "2022-02-01"
  #   Date.new(2022, 2, 4).to_s  # => "2022-02-04"
  #
  # Argument +month+ should be in range (1..12) or range (-12..-1);
  # when the argument is negative, counts backward from the end of the year:
  #
  #   Date.new(2022, -11, 4).to_s # => "2022-02-04"
  #
  # Argument +mday+ should be in range (1..n) or range (-n..-1)
  # where +n+ is the number of days in the month;
  # when the argument is negative, counts backward from the end of the month.
  #
  # See argument {start}[rdoc-ref:language/calendars.rdoc@Argument+start].
  #
  # Related: Date.jd.
  def initialize(year = -4712, month = 1, day = 1, start = DEFAULT_SG)
    # argument type checking
    raise TypeError, "invalid year (not numeric)" unless year.is_a?(Numeric)
    raise TypeError, "invalid month (not numeric)" unless month.is_a?(Numeric)
    raise TypeError, "invalid day (not numeric)" unless day.is_a?(Numeric)

    @sg = start

    year_int, year_frac = extract_fraction(year)
    month_int, month_frac = extract_fraction(month)
    day_int, day_frac = extract_fraction(day)

    total_frac = year_frac + month_frac + day_frac

    result = self.class.send(:validate_civil, year_int, month_int, day_int, start)
    raise ArgumentError, "invalid date" unless result
    nth, ry, rm, rd, rjd, ns = result

    @nth = nth
    @year = ry
    @month = rm
    @day = rd
    @jd = rjd
    @has_jd = true
    @has_civil = true

    if total_frac.nonzero?
      self_plus = self + total_frac

      @nth = self_plus.instance_variable_get(:@nth)
      @jd = self_plus.instance_variable_get(:@jd)
      @year = self_plus.instance_variable_get(:@year)
      @month = self_plus.instance_variable_get(:@month)
      @day = self_plus.instance_variable_get(:@day)
      @has_jd = self_plus.instance_variable_get(:@has_jd)
      @has_civil = self_plus.instance_variable_get(:@has_civil)
    end
  end

  # Class methods
  class << self
    # call-seq:
    #   Date.jd(jd = 0, start = Date::ITALY) -> date
    #
    # Returns a new \Date object formed from the arguments:
    #
    #   Date.jd(2451944).to_s # => "2001-02-03"
    #   Date.jd(2451945).to_s # => "2001-02-04"
    #   Date.jd(0).to_s       # => "-4712-01-01"
    #
    # The returned date is:
    #
    # - Gregorian, if the argument is greater than or equal to +start+:
    #
    #     Date::ITALY                         # => 2299161
    #     Date.jd(Date::ITALY).gregorian?     # => true
    #     Date.jd(Date::ITALY + 1).gregorian? # => true
    #
    # - Julian, otherwise
    #
    #     Date.jd(Date::ITALY - 1).julian?    # => true
    #
    # See argument {start}[rdoc-ref:language/calendars.rdoc@Argument+start].
    #
    # Related: Date.new.
    def jd(jd = 0, start = DEFAULT_SG)
      raise TypeError, "invalid jd (not numeric)" unless jd.is_a?(Numeric)

      jd_int, fraction = extract_fraction(jd)

      nth = jd_int / CM_PERIOD
      rjd = jd_int % CM_PERIOD

      obj = allocate
      obj.instance_variable_set(:@nth, nth)
      obj.instance_variable_set(:@jd, rjd)
      obj.instance_variable_set(:@sg, start)
      obj.instance_variable_set(:@flags, HAVE_JD)
      obj.instance_variable_set(:@year, nil)
      obj.instance_variable_set(:@month, nil)
      obj.instance_variable_set(:@day, nil)

      obj = obj.send(:add_fraction, fraction) if fraction.nonzero?

      obj
    end

    # call-seq:
    #   Date.gregorian_leap?(year) -> true or false
    #
    # Returns +true+ if the given year is a leap year
    # in the {proleptic Gregorian calendar}[https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar], +false+ otherwise:
    #
    #   Date.gregorian_leap?(2000) # => true
    #   Date.gregorian_leap?(2001) # => false
    #
    # Related: Date.julian_leap?.
    def gregorian_leap?(year)
      !!(((year % 4).zero? && (year % 100).nonzero?) || (year % 400).zero?)
    end

    # call-seq:
    #   Date.julian_leap?(year) -> true or false
    #
    # Returns +true+ if the given year is a leap year
    # in the {proleptic Julian calendar}[https://en.wikipedia.org/wiki/Proleptic_Julian_calendar], +false+ otherwise:
    #
    #   Date.julian_leap?(1900) # => true
    #   Date.julian_leap?(1901) # => false
    #
    # Related: Date.gregorian_leap?.
    def julian_leap?(year)
      (year % 4).zero?
    end

    # call-seq:
    #   Date.ordinal(year = -4712, yday = 1, start = Date::ITALY) -> date
    #
    # Returns a new \Date object formed fom the arguments.
    #
    # With no arguments, returns the date for January 1, -4712:
    #
    #   Date.ordinal.to_s # => "-4712-01-01"
    #
    # With argument +year+, returns the date for January 1 of that year:
    #
    #   Date.ordinal(2001).to_s  # => "2001-01-01"
    #   Date.ordinal(-2001).to_s # => "-2001-01-01"
    #
    # With positive argument +yday+ == +n+,
    # returns the date for the +nth+ day of the given year:
    #
    #   Date.ordinal(2001, 14).to_s # => "2001-01-14"
    #
    # With negative argument +yday+, counts backward from the end of the year:
    #
    #   Date.ordinal(2001, -14).to_s # => "2001-12-18"
    #
    # Raises an exception if +yday+ is zero or out of range.
    #
    # See argument {start}[rdoc-ref:language/calendars.rdoc@Argument+start].
    #
    # Related: Date.jd, Date.new.
    def ordinal(year = -4712, yday = 1, start = DEFAULT_SG)
      raise TypeError, "invalid year (not numeric)" unless year.is_a?(Numeric)
      raise TypeError, "invalid yday (not numeric)" unless yday.is_a?(Numeric)

      year, year_frac = extract_fraction(year)
      yday, yday_frac = extract_fraction(yday)
      total_frac = year_frac + yday_frac

      result = validate_ordinal(year, yday, start)

      raise ArgumentError, "invalid date" unless result

      nth, ry, rd, rjd, ns = result

      obj = allocate
      obj.instance_variable_set(:@nth, nth)
      obj.instance_variable_set(:@jd, rjd)
      obj.instance_variable_set(:@sg, start)
      obj.instance_variable_set(:@flags, HAVE_JD)
      obj.instance_variable_set(:@year, nil)
      obj.instance_variable_set(:@month, nil)
      obj.instance_variable_set(:@day, nil)

      obj = obj + total_frac if total_frac.nonzero?

      obj
    end

    # call-seq:
    #   Date.valid_ordinal?(year, yday, start = Date::ITALY) -> true or false
    #
    # Returns +true+ if the arguments define a valid ordinal date,
    # +false+ otherwise:
    #
    #   Date.valid_ordinal?(2001, 34)  # => true
    #   Date.valid_ordinal?(2001, 366) # => false
    #
    # See argument {start}[rdoc-ref:language/calendars.rdoc@Argument+start].
    #
    # Related: Date.jd, Date.ordinal.
    def valid_ordinal?(year, day, start = DEFAULT_SG)
      return false unless year.is_a?(Numeric) || year.respond_to?(:to_int)
      return false unless day.is_a?(Numeric) || day.respond_to?(:to_int)

      year = convert_to_integer(year)
      day = convert_to_integer(day)

      return false if year.zero?

      leap_year = start == JULIAN ? julian_leap?(year) : gregorian_leap?(year)
      max_day = leap_year ? 366 : 365

      day >= 1 && day <= max_day
    end

    # call-seq:
    #   Date.commercial(cwyear = -4712, cweek = 1, cwday = 1, start = Date::ITALY) -> date
    #
    # Returns a new \Date object constructed from the arguments.
    #
    # Argument +cwyear+ gives the year, and should be an integer.
    #
    # Argument +cweek+ gives the index of the week within the year,
    # and should be in range (1..53) or (-53..-1);
    # in some years, 53 or -53 will be out-of-range;
    # if negative, counts backward from the end of the year:
    #
    #   Date.commercial(2022, 1, 1).to_s  # => "2022-01-03"
    #   Date.commercial(2022, 52, 1).to_s # => "2022-12-26"
    #
    # Argument +cwday+ gives the indes of the weekday within the week,
    # and should be in range (1..7) or (-7..-1);
    # 1 or -7 is Monday;
    # if negative, counts backward from the end of the week:
    #
    #   Date.commercial(2022, 1, 1).to_s  # => "2022-01-03"
    #   Date.commercial(2022, 1, -7).to_s # => "2022-01-03"
    #
    # When +cweek+ is 1:
    #
    # - If January 1 is a Friday, Saturday, or Sunday,
    #   the first week begins in the week after:
    #
    #     Date::ABBR_DAYNAMES[Date.new(2023, 1, 1).wday] # => "Sun"
    #     Date.commercial(2023, 1, 1).to_s # => "2023-01-02"
    #     Date.commercial(2023, 1, 7).to_s # => "2023-01-08"
    #
    # - Otherwise, the first week is the week of January 1,
    #   which may mean some of the days fall on the year before:
    #
    #     Date::ABBR_DAYNAMES[Date.new(2020, 1, 1).wday] # => "Wed"
    #     Date.commercial(2020, 1, 1).to_s # => "2019-12-30"
    #     Date.commercial(2020, 1, 7).to_s # => "2020-01-05"
    #
    # See argument {start}[rdoc-ref:language/calendars.rdoc@Argument+start].
    #
    # Related: Date.jd, Date.new, Date.ordinal.
    def commercial(cwyear = -4712, cweek = 1, cwday = 1, start = DEFAULT_SG)
      raise TypeError, "invalid year (not numeric)" unless cwyear.is_a?(Numeric)
      raise TypeError, "invalid cweek (not numeric)" unless cweek.is_a?(Numeric)
      raise TypeError, "invalid cwday (not numeric)" unless cwday.is_a?(Numeric)

      cwyear_int, year_frac = extract_fraction(cwyear)
      cweek_int, week_frac = extract_fraction(cweek)
      cwday_int, day_frac = extract_fraction(cwday)
      total_frac = year_frac + week_frac + day_frac

      # Validate ISO week date
      result = validate_commercial(cwyear_int, cweek_int, cwday_int, start)

      raise ArgumentError, "invalid date" unless result

      nth, ry, rw, rd, rjd, ns = result

      obj = allocate
      obj.instance_variable_set(:@nth, nth)
      obj.instance_variable_set(:@jd, rjd)
      obj.instance_variable_set(:@sg, start)
      obj.instance_variable_set(:@has_jd, true)
      obj.instance_variable_set(:@has_civil, false)
      obj.instance_variable_set(:@year, nil)
      obj.instance_variable_set(:@month, nil)
      obj.instance_variable_set(:@day, nil)

      obj = obj + total_frac if total_frac.nonzero?

      obj
    end

    # call-seq:
    #   Date.today(start = Date::ITALY) -> date
    #
    # Returns a new \Date object constructed from the present date:
    #
    #   Date.today.to_s # => "2022-07-06"
    #
    # See argument {start}[rdoc-ref:language/calendars.rdoc@Argument+start].
    def today(start = DEFAULT_SG)
      begin
        time = Time.now
      rescue => e
        raise SystemCallError, "time"
      end

      begin
        y = time.year
        m = time.month
        d = time.day
      rescue => e
        raise SystemCallError, "localtime"
      end

      nth, ry, _, _ = decode_year(y, -1)

      obj = allocate
      obj.instance_variable_set(:@nth, nth)
      obj.instance_variable_set(:@year, ry)
      obj.instance_variable_set(:@month, m)
      obj.instance_variable_set(:@day, d)
      obj.instance_variable_set(:@jd, nil)
      obj.instance_variable_set(:@sg, GREGORIAN)
      obj.instance_variable_set(:@has_jd, false)
      obj.instance_variable_set(:@has_civil, true)

      if start != GREGORIAN
        obj.instance_variable_set(:@sg, start)
        if obj.instance_variable_get(:@has_jd)
          obj.instance_variable_set(:@jd, nil)
          obj.instance_variable_set(:@has_jd, false)
        end
      end

      obj
    end

    private

    # Optimized: Gregorian date -> Julian Day Number
    def gregorian_civil_to_jd(year, month, day)
      # Shift epoch to March 1 of year 0 (Jan/Feb belong to previous year)
      j = (month < 3) ? 1 : 0
      y0 = year - j
      m0 = j == 1 ? month + 12 : month
      d0 = day - 1

      # Calculate year contribution with leap year correction
      q1 = y0 / NS_YEARS_PER_CENTURY
      yc = (NS_DAYS_IN_4_YEARS * y0) / 4 - q1 + (q1 / 4)

      # Calculate month contribution using integer arithmetic
      mc = (NS_CIVIL_MONTH_COEFF * m0 - NS_CIVIL_MONTH_OFFSET) / NS_CIVIL_MONTH_DIVISOR

      # Combine and add epoch offset to get JDN
      yc + mc + d0 + NS_EPOCH
    end

    def julian_civil_to_jd(y, m, d)
      # Traditional Julian calendar algorithm
      y2 = y
      m2 = m

      if m2 <= 2
        y2 -= 1
        m2 += 12
      end

      (365.25 * (y2 + 4716)).floor + (30.6001 * (m2 + 1)).floor + d - 1524
    end

    def validate_ordinal(year, yday, sg)
      # Handling negative day of year
      if yday < 0
        # Counting backwards from the end of the year
        last_jd = find_last_day_of_year(year, sg)
        return nil unless last_jd

        # Recalculate the total number of days in the year from the calculated JD
        adjusted_jd = last_jd + yday + 1
        y, d = jd_to_ordinal(adjusted_jd, sg)

        # Invalid if the year does not match
        return nil if y != year

        yday = d
      end

      # Calculate jd from the day of the year
      nth, ry, _, _ = decode_year(year, sg)
      first_jd, ns = find_first_day_of_year(ry, sg)

      return nil unless first_jd

      jd = first_jd + yday - 1

      # Verify that the calculated jd actually belongs to the specified year
      verify_y, verify_d = jd_to_ordinal(jd, sg)
      return nil if verify_y != ry || verify_d != yday

      [nth, ry, yday, jd, ns]
    end

    def find_first_day_of_year(year, sg)
      # Equivalent to `c_find_fdoy` in the C implementation
      (1..31).each do |day|
        if valid_civil_date?(year, 1, day, sg)
          jd, ns = civil_to_jd_with_check(year, 1, day, sg)

          return [jd, ns]
        end
      end
      nil
    end

    def find_last_day_of_year(year, sg)
      # Equivalent to `c_find_ldoy` in the C implementation
      (0..29).each do |i|
        day = 31 - i
        if valid_civil_date?(year, 12, day, sg)
          jd, ns = civil_to_jd_with_check(year, 12, day, sg)

          return jd
        end
      end
      nil
    end

    def extract_fraction(value)
      if value.is_a?(Rational) || value.is_a?(Float)
        int_part = value.floor
        frac_part = value - int_part
        [int_part, frac_part]
      else
        [value.to_i, 0]
      end
    end

    def jd_to_ordinal(jd, sg)
      year, month, day = jd_to_civil_internal(jd, sg)
      first_jd, ns = find_first_day_of_year(year, sg)
      yday = jd - first_jd + 1
      [year, yday]
    end

    def validate_commercial(year, week, day, sg)
      if day < 0
        day += 8  # -1 -> 7 (Sun), -7 -> 1 (Mon)
      end

      return nil if day < 1 || day > 7

      if week < 0
        next_year_jd, ns = commercial_to_jd_internal(year + 1, 1, 1, sg)
        return nil unless next_year_jd

        adjusted_jd = next_year_jd + week * 7
        y2, w2, _ = jd_to_commercial_internal(adjusted_jd, sg)

        return nil if y2 != year

        week = w2
      end

      # Calculate jd from ISO week date
      nth, ry, _, _ = decode_year(year, sg)
      jd, ns = commercial_to_jd_internal(ry, week, day, sg)

      return nil unless jd

      verify_y, verify_w, verify_d = jd_to_commercial_internal(jd, sg)
      return nil if verify_y != ry || verify_w != week || verify_d != day

      [nth, ry, week, day, jd, ns]
    end

    def commercial_to_jd_internal(cwyear, cweek, cwday, sg)
      # Calculating ISO week date(The week containing January 4 is week 1)
      jan4_jd = gregorian_civil_to_jd(cwyear, 1, 4)

      # Day of the week on which January 4th falls
      # (0 = Sun, 1 = Mon, ..., 6 = Sat)
      jan4_wday = (jan4_jd + 1) % 7

      # Monday of week 1
      week1_mon = jan4_jd - jan4_wday + 1

      # jd for a specified weekday
      jd = week1_mon + (cweek - 1) * 7 + (cwday - 1)

      # If before sg, it is the Julian calendar
      ns = jd >= sg ? 1 : 0

      [jd, ns]
    end

    def jd_to_commercial_internal(jd, sg)
      # get date from jd
      year, month, day = jd_to_civil_internal(jd, sg)

      # calculate jd for January 4 of that year
      jan4_jd = gregorian_civil_to_jd(year, 1, 4)
      jan4_wday = (jan4_jd + 1) % 7
      week1_mon = jan4_jd - jan4_wday + 1

      # If jd is before the first week, it belongs to the previous year
      if jd < week1_mon
        year -= 1
        jan4_jd = gregorian_civil_to_jd(year, 1, 4)
        jan4_wday = (jan4_jd + 1) % 7
        week1_mon = jan4_jd - jan4_wday + 1
      end

      # check the first week of the next year
      next_jan4 = gregorian_civil_to_jd(year + 1, 1, 4)
      next_jan4_wday = (next_jan4 + 1) % 7
      next_week1_mon = next_jan4 - next_jan4_wday + 1

      if jd >= next_week1_mon
        year += 1
        week1_mon = next_week1_mon
      end

      # Calculate the week number
      week = (jd - week1_mon) / 7 + 1

      # week(1 = mon, ..., 7 = sun）
      cwday = (jd + 1) % 7
      cwday = 7 if cwday == 0

      [year, week, cwday]
    end

    def jd_to_civil_internal(jd, sg)
      # Does it overlap with jd_to_civil?
      # Calculate the date from jd (using existing methods)
      # simple version
      r0 = jd - NS_EPOCH

      n1 = 4 * r0 + 3
      q1 = n1 / NS_DAYS_IN_400_YEARS
      r1 = (n1 % NS_DAYS_IN_400_YEARS) / 4

      n2 = 4 * r1 + 3
      u2 = NS_YEAR_MULTIPLIER * n2
      q2 = u2 >> 32
      r2 = (u2 & 0xFFFFFFFF) / NS_YEAR_MULTIPLIER / 4

      n3 = NS_MONTH_COEFF * r2 + NS_MONTH_OFFSET
      q3 = n3 >> 16
      r3 = (n3 & 0xFFFF) / NS_MONTH_COEFF

      y0 = NS_YEARS_PER_CENTURY * q1 + q2
      j = (r2 >= NS_DAYS_BEFORE_NEW_YEAR) ? 1 : 0

      year = y0 + j
      month = j == 1 ? q3 - 12 : q3
      day = r3 + 1

      [year, month, day]
    end

    def decode_year(year, style)
      period = (style < 0) ? 146097 * 400 : 1461 * 4

      if year.is_a?(Integer) && year.abs < 1000000
        [0, year, nil, nil]
      else
        adjusted = year + 4712
        nth = adjusted / period
        ry = (adjusted % period) - 4712

        [nth, ry, nil, nil]
      end
    end

    def valid_civil_date?(year, month, day, sg)
      return false if month < 1 || month > 12

      if sg == GREGORIAN || sg < 0
        last_day = last_day_of_month_gregorian(year, month)
      elsif sg == JULIAN || sg > 0
        last_day = last_day_of_month_julian(year, month)
      else
        # Calculate (calendar reform period - jd) and determine
        jd = gregorian_civil_to_jd(year, month, day)

        if jd < sg
          last_day = last_day_of_month_julian(year, month)
        else
          last_day = last_day_of_month_gregorian(year, month)
        end
      end

      return false if day < 1 || day > last_day

      true
    end

    def last_day_of_month_gregorian(y, m)
      return nil if m < 1 || m > 12

      leap_index = gregorian_leap?(y) ? 1 : 0
      MONTH_DAYS[leap_index][m]
    end

    def last_day_of_month_julian(y, m)
      return nil if m < 1 || m > 12

      leap_index = julian_leap?(y) ? 1 : 0
      MONTH_DAYS[leap_index][m]
    end

    def civil_to_jd_with_check(year, month, day, sg)
      return nil unless valid_civil_date?(year, month, day, sg)

      jd, ns = civil_to_jd(year, month, day, sg)

      [jd, ns]
    end

    def civil_to_jd(year, month, day, sg)
      if sg == GREGORIAN
        jd = gregorian_civil_to_jd(year, month, day)

        return [jd, 1]
      end

      jd = gregorian_civil_to_jd(year, month, day)

      if jd < sg
        jd = julian_civil_to_jd(year, month, day)
        ns = 0
      else
        ns = 1
      end

      [jd, ns]
    end

    def last_day_of_month_for_sg(year, month, sg)
      last_day_of_month_gregorian(year, month)
    end

    def validate_civil(year, month, day, sg)
      month += 13 if month < 0
      return nil if month < 1 || month > 12

      if day < 0
        last_day = last_day_of_month_gregorian(year, month)
        return nil unless last_day
        day = last_day + day + 1
      end

      last_day = last_day_of_month_gregorian(year, month)
      return nil if day < 1 || day > last_day

      nth, ry = decode_year(year, -1)

      jd, ns = civil_to_jd_with_style(ry, month, day, sg)

      [nth, ry, month, day, jd, ns]
    end

    def civil_to_jd_with_style(year, month, day, sg)
      jd = gregorian_civil_to_jd(year, month, day)

      if jd < sg
        jd = julian_civil_to_jd(year, month, day)
        ns = 0
      else
        ns = 1
      end

      [jd, ns]
    end

    def find_last_day_of_month(year, month, sg)
      (0..29).each do |i|
        day = 31 - i
        if valid_civil_date?(year, month, day, sg)
          jd = civil_to_jd(year, month, day, sg)

          return jd
        end
      end

      nil
    end

    def convert_to_integer(value)
      if value.respond_to?(:to_int)
        value.to_int
      elsif value.is_a?(Numeric)
        value.to_i
      else
        value
      end
    end
  end

  # Instance methods

  # call-seq:
  #   year -> integer
  #
  # Returns the year:
  #
  #   Date.new(2001, 2, 3).year    # => 2001
  #   (Date.new(1, 1, 1) - 1).year # => 0
  def year
    @year ||= jd_to_civil[0]
  end

  # call-seq:
  #   mon -> integer
  #
  # Returns the month in range (1..12):
  #
  #   Date.new(2001, 2, 3).mon # => 2
  def month
    @month ||= jd_to_civil[1]
  end
  alias mon month

  def day
    @day ||= jd_to_civil[2]
  end
  alias mday day

  # call-seq:
  #    d.jd  ->  integer
  #
  # Returns the Julian day number.  This is a whole number, which is
  # adjusted by the offset as the local time.
  #
  #    DateTime.new(2001,2,3,4,5,6,'+7').jd    #=> 2451944
  #    DateTime.new(2001,2,3,4,5,6,'-7').jd    #=> 2451944
  def jd
    if @nth.zero?
      @jd
    else
      @nth * CM_PERIOD + @jd
    end
  end

  # call-seq:
  #   start -> float
  #
  # Returns the Julian start date for calendar reform;
  # if not an infinity, the returned value is suitable
  # for passing to Date#jd:
  #
  #   d = Date.new(2001, 2, 3, Date::ITALY)
  #   s = d.start     # => 2299161.0
  #   Date.jd(s).to_s # => "1582-10-15"
  #
  #   d = Date.new(2001, 2, 3, Date::ENGLAND)
  #   s = d.start     # => 2361222.0
  #   Date.jd(s).to_s # => "1752-09-14"
  #
  #   Date.new(2001, 2, 3, Date::GREGORIAN).start # => -Infinity
  #   Date.new(2001, 2, 3, Date::JULIAN).start    # => Infinity
  #
  # See argument {start}[rdoc-ref:language/calendars.rdoc@Argument+start].
  def start
    @sg
  end

  # call-seq:
  #   self <=> other  -> -1, 0, 1 or nil
  #
  # Compares +self+ and +other+, returning:
  #
  # - <tt>-1</tt> if +other+ is larger.
  # - <tt>0</tt> if the two are equal.
  # - <tt>1</tt> if +other+ is smaller.
  # - +nil+ if the two are incomparable.
  #
  # Argument +other+ may be:
  #
  # - Another \Date object:
  #
  #     d = Date.new(2022, 7, 27) # => #<Date: 2022-07-27 ((2459788j,0s,0n),+0s,2299161j)>
  #     prev_date = d.prev_day    # => #<Date: 2022-07-26 ((2459787j,0s,0n),+0s,2299161j)>
  #     next_date = d.next_day    # => #<Date: 2022-07-28 ((2459789j,0s,0n),+0s,2299161j)>
  #     d <=> next_date           # => -1
  #     d <=> d                   # => 0
  #     d <=> prev_date           # => 1
  #
  # - A DateTime object:
  #
  #     d <=> DateTime.new(2022, 7, 26) # => 1
  #     d <=> DateTime.new(2022, 7, 27) # => 0
  #     d <=> DateTime.new(2022, 7, 28) # => -1
  #
  # - A numeric (compares <tt>self.ajd</tt> to +other+):
  #
  #     d <=> 2459788 # => -1
  #     d <=> 2459787 # => 1
  #     d <=> 2459786 # => 1
  #     d <=> d.ajd   # => 0
  #
  # - Any other object:
  #
  #     d <=> Object.new # => nil
  def <=>(other)
    return nil unless other.is_a?(RubyDate)

    nth_cmp = @nth <=> other.instance_variable_get(:@nth)
    return nth_cmp unless nth_cmp.zero?

    @jd <=> other.instance_variable_get(:@jd)
  end

  def ==(other) # :nodoc:
    return false unless other.is_a?(RubyDate)

    @nth == other.instance_variable_get(:@nth) &&
    @jd == other.instance_variable_get(:@jd)
  end

  def eql?(other) # :nodoc:
    return false unless other.is_a?(RubyDate)

    @nth == other.instance_variable_get(:@nth) &&
    @jd == other.instance_variable_get(:@jd) &&
    @sg == other.instance_variable_get(:@sg)
  end

  def hash # :nodoc:
    [@nth, @jd, @sg].hash
  end

  # call-seq:
  #    d + other  ->  date
  #
  # Returns a date object pointing +other+ days after self.  The other
  # should be a numeric value.  If the other is a fractional number,
  # assumes its precision is at most nanosecond.
  #
  #    Date.new(2001,2,3) + 1    #=> #<Date: 2001-02-04 ...>
  #    DateTime.new(2001,2,3) + Rational(1,2)
  #                              #=> #<DateTime: 2001-02-03T12:00:00+00:00 ...>
  #    DateTime.new(2001,2,3) + Rational(-1,2)
  #                              #=> #<DateTime: 2001-02-02T12:00:00+00:00 ...>
  #    DateTime.jd(0,12) + DateTime.new(2001,2,3).ajd
  #                              #=> #<DateTime: 2001-02-03T00:00:00+00:00 ...>
  def +(n)
    return self if n.zero?

    if n.is_a?(Rational) || n.is_a?(Float)
      add_with_fraction(n)
    else
      add_days(n.to_i)
    end
  end

  # call-seq:
  #   infinite? -> false
  #
  # Returns +false+
  def infinite?
    false
  end

  class Infinity < Numeric # :nodoc:
    def initialize(d = 1)
      @d = d <=> 0
    end

    def d
      @d
    end

    protected :d

    def zero?
      false
    end

    def finite?
      false
    end

    def infinite?
      d.nonzero?
    end

    def nan?
      d.zero?
    end

    def abs
      self.class.new
    end

    def -@
      self.class.new(-d)
    end

    def +@
      self.class.new(+d)
    end

    def <=>(other)
      case other
      when Infinity
        return d <=> other.d
      when Float::INFINITY
        return d <=> 1
      when -Float::INFINITY
        return d <=> -1
      when Numeric
        return d
      else
        begin
          l, r = other.coerce(self)
          return l <=> r
        rescue NoMethodError
        end
      end
      nil
    end

    def coerce(other)
      case other
      when Numeric
        return -d, d
      else
        super
      end
    end

    def to_f
      return 0 if @d.zero?
      if @d > 0
        Float::INFINITY
      else
        -Float::INFINITY
      end
    end
  end

  def to_s
    sprintf("%04d-%02d-%02d", year, month, day)
  end

  def inspect
    "#<#{self.class}: #{to_s} ((#{jd}j,0s,0n),+0s,#{@sg.to_i}j)>"
  end

  private

  def valid_civil?(y, m, d)
    return false if m < 1 || m > 12

    last = last_day_of_month(y, m)
    d >= 1 && d <= last
  end

  def last_day_of_month(y, m)
    last_day_of_month_gregorian(y, m)
  end

  def civil_to_jd(y, m, d, sg)
    self.class.send(:gregorian_civil_to_jd, y, m, d)
  end

  def jd_to_civil
    return [@year, @month, @day] if @year && @month && @day

    jd = @jd
    sg = @sg

    # Original algorithm from date_core.c
    if jd < sg
      # Julian calendar
      a = jd
    else
      # Gregorian calendar
      x = ((jd - 1867216.25) / 36524.25).floor
      a = jd + 1 + x - (x / 4.0).floor
    end

    b = a + 1524
    c = ((b - 122.1) / 365.25).floor
    d = (365.25 * c).floor
    e = ((b - d) / 30.6001).floor

    dom = b - d - (30.6001 * e).floor

    if e <= 13
      month = e - 1
      year = c - 4716
    else
      month = e - 13
      year = c - 4715
    end

    @year = year.to_i
    @month = month.to_i
    @day = dom.to_i

    [@year, @month, @day]
  end

  def extract_fraction(value)
    self.class.send(:extract_fraction, value)
  end

  def guess_style(year, sg)
    return sg if sg.infinite?
    return year > 0 ? GREGORIAN : JULIAN unless year.is_a?(Integer)

    if year < REFORM_BEGIN_YEAR
      JULIAN
    elsif year > REFORM_END_YEAR
      GREGORIAN
    else
      0
    end
  end

  def decode_year(year, style)
    self.class.send(:decode_year, year, style)
  end

  def valid_gregorian?(y, m, d)
    return false if m < 1 || m > 12

    # Handling negative months and days
    m = m + 13 if m < 0
    return false if m < 1 || m > 12

    last_day = last_day_of_month_gregorian(y, m)
    d = last_day + d + 1 if d < 0

    d >= 1 && d <= last_day
  end

  def add_with_fraction(n)
    int_part = n.floor
    frac_part = n - int_part

    result = add_days(int_part)

    if frac_part != 0
      result = result.send(:add_fraction, frac_part)
    end

    result
  end

  def add_days(days)
    new_jd = @jd + days
    new_nth = @nth

    while new_jd < 0
      new_nth -= 1
      new_jd += CM_PERIOD
    end

    while new_jd >= CM_PERIOD
      new_nth += 1
      new_jd -= CM_PERIOD
    end

    obj = self.class.allocate
    obj.instance_variable_set(:@nth, new_nth)
    obj.instance_variable_set(:@jd, new_jd)
    obj.instance_variable_set(:@sg, @sg)
    obj.instance_variable_set(:@flags, HAVE_JD)
    obj.instance_variable_set(:@year, nil)
    obj.instance_variable_set(:@month, nil)
    obj.instance_variable_set(:@day, nil)

    obj
  end

  def add_fraction(frac)
    # In the C implementation, Date.jd(2451944.5) becomes 2451945,
    # so if there is a decimal point, it will be rounded up by one day.
    if frac > 0
      add_days(1)
    else
      self
    end
  end

  def last_day_of_month_gregorian(y, m)
    self.class.send(:last_day_of_month_gregorian, y, m)
  end

  def last_day_of_month_julian(y, m)
    self.class.send(:last_day_of_month_julian, y, m)
  end

  def valid_civil_date?(year, month, day, sg)
    self.class.send(:valid_civil_date?, year, month, day, sg)
  end
end
