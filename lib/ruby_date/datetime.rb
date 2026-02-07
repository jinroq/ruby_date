# frozen_string_literal: true

# Implementation of DateTime from ruby/date/ext/date/date_core.c
# DateTime is a subclass of Date that includes time-of-day and timezone.
class RubyDateTime < RubyDate
  # call-seq:
  #   DateTime.new(year=-4712, month=1, day=1, hour=0, minute=0, second=0, offset=0, start=Date::ITALY) -> datetime
  #
  # Creates a new DateTime object.
  def initialize(year = -4712, month = 1, day = 1, hour = 0, minute = 0, second = 0, offset = 0, start = DEFAULT_SG)
    y = year
    m = month
    d = day
    h = hour
    min = minute
    s = second
    fr2 = 0

    # argument type checking
    raise TypeError, "invalid year (not numeric)" unless y.is_a?(Numeric)
    raise TypeError, "invalid month (not numeric)" unless m.is_a?(Numeric)
    raise TypeError, "invalid day (not numeric)" unless d.is_a?(Numeric)
    raise TypeError, "invalid hour (not numeric)" unless h.is_a?(Numeric)
    raise TypeError, "invalid minute (not numeric)" unless min.is_a?(Numeric)
    raise TypeError, "invalid second (not numeric)" unless s.is_a?(Numeric)

    # Handle fractional day (C: d_trunc)
    d_trunc, fr = d_trunc_with_frac(d)
    d = d_trunc
    fr2 = fr if fr.nonzero?

    # Handle fractional hour (C: h_trunc via num2int_with_frac)
    h_int = h.to_i
    h_frac = h - h_int
    if h_frac.nonzero?
      fr2 = fr2 + Rational(h_frac) / 24
      h = h_int
    end

    # Handle fractional minute (C: min_trunc)
    min_int = min.to_i
    min_frac = min - min_int
    if min_frac.nonzero?
      fr2 = fr2 + Rational(min_frac) / 1440
      min = min_int
    end

    # Handle fractional second (C: s_trunc)
    # C converts sub-second fraction to day fraction: fr2 = frac / DAY_IN_SECONDS
    s_int = s.to_i
    s_frac = s - s_int
    if s_frac.nonzero?
      fr2 = fr2 + Rational(s_frac) / DAY_IN_SECONDS
      s = s_int
    end

    # Convert offset to integer seconds (C: val2off → offset_to_sec)
    rof = offset_to_sec(offset)

    sg = self.class.send(:valid_sg, start)
    style = self.class.send(:guess_style, y, sg)

    # Validate time (C: c_valid_time_p)
    h, min, s = validate_time(h, min, s)

    # Handle hour 24 (C: canon24oc)
    if h == 24
      h = 0
      fr2 = fr2 + 1
    end

    if style < 0
      # gregorian calendar only
      result = self.class.send(:valid_gregorian_p, y, m, d)
      raise Error, "invalid date" unless result

      nth, ry = self.class.send(:decode_year, y, -1)
      rm = result[:rm]
      rd = result[:rd]

      rjd, _ = self.class.send(:c_civil_to_jd, ry, rm, rd, GREGORIAN)
      rjd2 = jd_local_to_utc(rjd, time_to_df(h, min, s), rof)

      @nth = canon(nth)
      @jd = rjd2
      @sg = sg
      @year = ry
      @month = rm
      @day = rd
      @has_jd = true
      @has_civil = true
      @hour = h
      @min = min
      @sec = s
      @df = time_to_df(h, min, s)
      @sf = 0
      @of = rof
    else
      # full validation
      result = self.class.send(:valid_civil_p, y, m, d, sg)
      raise Error, "invalid date" unless result

      nth = result[:nth]
      ry = result[:ry]
      rm = result[:rm]
      rd = result[:rd]
      rjd = result[:rjd]

      rjd2 = jd_local_to_utc(rjd, time_to_df(h, min, s), rof)

      @nth = canon(nth)
      @jd = rjd2
      @sg = sg
      @year = ry
      @month = rm
      @day = rd
      @has_jd = true
      @has_civil = true
      @hour = h
      @min = min
      @sec = s
      @df = time_to_df(h, min, s)
      @sf = 0
      @of = rof
    end

    # Add accumulated fractional parts (C: add_frac)
    if fr2.nonzero?
      new_date = self + fr2
      @nth = new_date.instance_variable_get(:@nth)
      @jd = new_date.instance_variable_get(:@jd)
      @sg = new_date.instance_variable_get(:@sg)
      @year = new_date.instance_variable_get(:@year)
      @month = new_date.instance_variable_get(:@month)
      @day = new_date.instance_variable_get(:@day)
      @has_jd = new_date.instance_variable_get(:@has_jd)
      @has_civil = new_date.instance_variable_get(:@has_civil)
      @hour = new_date.instance_variable_get(:@hour)
      @min = new_date.instance_variable_get(:@min)
      @sec = new_date.instance_variable_get(:@sec)
      @df = new_date.instance_variable_get(:@df) || @df
      @sf = new_date.instance_variable_get(:@sf) || @sf
      @of = new_date.instance_variable_get(:@of) || @of
    end

    self
  end

  # --- DateTime accessors (C: d_lite_hour etc.) ---

  # call-seq:
  #   hour -> integer
  #
  # Returns the hour in range (0..23).
  def hour
    if simple_dat_p?
      0
    else
      get_c_time
      @hour || 0
    end
  end

  # call-seq:
  #   min -> integer
  #
  # Returns the minute in range (0..59).
  def min
    if simple_dat_p?
      0
    else
      get_c_time
      @min || 0
    end
  end
  alias minute min

  # call-seq:
  #   sec -> integer
  #
  # Returns the second in range (0..59).
  def sec
    if simple_dat_p?
      0
    else
      get_c_time
      @sec || 0
    end
  end
  alias second sec

  # call-seq:
  #   sec_fraction -> rational
  #
  # Returns the fractional part of the second:
  #
  #   DateTime.new(2001, 2, 3, 4, 5, 6.5).sec_fraction # => (1/2)
  #
  # C: m_sf_in_sec = ns_to_sec(m_sf)
  def sec_fraction
    ns = m_sf
    ns.zero? ? Rational(0) : Rational(ns, SECOND_IN_NANOSECONDS)
  end
  alias second_fraction sec_fraction

  # call-seq:
  #   offset -> rational
  #
  # Returns the offset as a fraction of day:
  #
  #   DateTime.parse('04pm+0730').offset # => (5/16)
  #
  # C: m_of_in_day = isec_to_day(m_of)
  def offset
    of = m_of
    of.zero? ? Rational(0) : Rational(of, DAY_IN_SECONDS)
  end

  # call-seq:
  #   zone -> string
  #
  # Returns the timezone as a string:
  #
  #   DateTime.parse('04pm+0730').zone # => "+07:30"
  #
  # C: m_zone → of2str(m_of)
  def zone
    if simple_dat_p?
      "+00:00"
    else
      of = m_of
      s = of < 0 ? '-' : '+'
      a = of < 0 ? -of : of
      h = a / HOUR_IN_SECONDS
      m = a % HOUR_IN_SECONDS / MINUTE_IN_SECONDS
      "%c%02d:%02d" % [s, h, m]
    end
  end

  # call-seq:
  #   deconstruct_keys(array_of_names_or_nil) -> hash
  #
  # Returns name/value pairs for pattern matching.
  # Includes Date keys (:year, :month, :day, :wday, :yday)
  # plus DateTime keys (:hour, :min, :sec, :sec_fraction, :zone).
  #
  # C: dt_lite_deconstruct_keys (is_datetime=true)
  def deconstruct_keys(keys)
    if keys.nil?
      return {
        year: year,
        month: month,
        day: day,
        yday: yday,
        wday: wday,
        hour: hour,
        min: min,
        sec: sec,
        sec_fraction: sec_fraction,
        zone: zone
      }
    end

    raise TypeError, "wrong argument type #{keys.class} (expected Array or nil)" unless keys.is_a?(Array)

    h = {}
    keys.each do |key|
      case key
      when :year         then h[:year]         = year
      when :month        then h[:month]        = month
      when :day          then h[:day]          = day
      when :yday         then h[:yday]         = yday
      when :wday         then h[:wday]         = wday
      when :hour         then h[:hour]         = hour
      when :min          then h[:min]          = min
      when :sec          then h[:sec]          = sec
      when :sec_fraction then h[:sec_fraction] = sec_fraction
      when :zone         then h[:zone]         = zone
      end
    end
    h
  end

  # call-seq:
  #   to_s -> string
  #
  # Returns a string in ISO 8601 DateTime format:
  #
  #   DateTime.new(2001, 2, 3, 4, 5, 6, '+7').to_s
  #   # => "2001-02-03T04:05:06+07:00"
  def to_s
    sprintf("%04d-%02d-%02dT%02d:%02d:%02d%s", year, month, day, hour, min, sec, zone)
  end

  class << self
    # Same as DateTime.new
    alias_method :civil, :new

    # call-seq:
    #   DateTime.now(start = Date::ITALY) -> datetime
    #
    # Creates a DateTime for the current time.
    #
    # C: datetime_s_now
    def now(start = DEFAULT_SG)
      t = Time.now
      sg = valid_sg(start)

      of = t.utc_offset  # integer seconds

      new(
        t.year, t.mon, t.mday,
        t.hour, t.min, t.sec + Rational(t.nsec, 1_000_000_000),
        Rational(of, DAY_IN_SECONDS),
        sg
      )
    end

    # call-seq:
    #   DateTime.parse(string, comp = true, start = Date::ITALY, limit: 128) -> datetime
    #
    # Parses +string+ and creates a DateTime.
    #
    # C: date_parse → dt_new_by_frags
    def parse(string = JULIAN_EPOCH_DATETIME, comp = true, start = DEFAULT_SG, limit: 128)
      hash = _parse(string, comp, limit: limit)
      dt_new_by_frags(hash, start)
    end

    # Format-specific constructors delegate to _xxx + dt_new_by_frags

    def iso8601(string = JULIAN_EPOCH_DATETIME, start = DEFAULT_SG, limit: 128)
      hash = _iso8601(string, limit: limit)
      dt_new_by_frags(hash, start)
    end

    def rfc3339(string = JULIAN_EPOCH_DATETIME, start = DEFAULT_SG, limit: 128)
      hash = _rfc3339(string, limit: limit)
      dt_new_by_frags(hash, start)
    end

    def xmlschema(string = JULIAN_EPOCH_DATETIME, start = DEFAULT_SG, limit: 128)
      hash = _xmlschema(string, limit: limit)
      dt_new_by_frags(hash, start)
    end

    def rfc2822(string = JULIAN_EPOCH_DATETIME_RFC2822, start = DEFAULT_SG, limit: 128)
      hash = _rfc2822(string, limit: limit)
      dt_new_by_frags(hash, start)
    end
    alias_method :rfc822, :rfc2822

    def httpdate(string = JULIAN_EPOCH_DATETIME_HTTPDATE, start = DEFAULT_SG, limit: 128)
      hash = _httpdate(string, limit: limit)
      dt_new_by_frags(hash, start)
    end

    def jisx0301(string = JULIAN_EPOCH_DATETIME, start = DEFAULT_SG, limit: 128)
      hash = _jisx0301(string, limit: limit)
      dt_new_by_frags(hash, start)
    end

    private

    JULIAN_EPOCH_DATETIME = '-4712-01-01T00:00:00+00:00'
    JULIAN_EPOCH_DATETIME_RFC2822 = 'Mon, 1 Jan -4712 00:00:00 +0000'
    JULIAN_EPOCH_DATETIME_HTTPDATE = 'Mon, 01 Jan -4712 00:00:00 GMT'

    # C: dt_new_by_frags
    # Similar to d_new_by_frags but completes time fields and creates DateTime.
    def dt_new_by_frags(hash, sg)
      raise Error, "invalid date" if hash.nil? || hash.empty?

      y = hash[:year]
      m = hash[:mon]
      d = hash[:mday]

      h   = hash[:hour] || 0
      min = hash[:min]  || 0
      s   = hash[:sec]  || 0

      # Add sec_fraction if present
      if hash[:sec_fraction]
        s = s + hash[:sec_fraction]
      end

      # Convert offset (integer seconds) to Rational fraction of day
      of = hash[:offset] ? Rational(hash[:offset], DAY_IN_SECONDS) : 0

      # Fast path: year+mon+mday without jd/yday
      if !hash.key?(:jd) && !hash.key?(:yday) && y && m && d
        raise Error, "invalid date" unless valid_civil?(y, m, d, sg)
        return new(y, m, d, h, min, s, of, sg)
      end

      # Try to complete date fields
      if y && m
        raise Error, "invalid date" unless valid_civil?(y, m, 1, sg)
        return new(y, m, 1, h, min, s, of, sg)
      end

      if y
        raise Error, "invalid date" unless valid_civil?(y, 1, 1, sg)
        return new(y, 1, 1, h, min, s, of, sg)
      end

      raise Error, "invalid date"
    end
  end

  private

  # Convert offset argument to integer seconds.
  # Accepts: Integer (seconds), Rational (fraction of day), String ("+HH:MM"), 0
  # C: offset_to_sec / val2off
  def offset_to_sec(of)
    case of
    when Integer
      of
    when Rational
      # Fraction of day to seconds
      (of * DAY_IN_SECONDS).to_i
    when String
      if of.strip.upcase == 'Z'
        0
      elsif of =~ /\A([+-])(\d{2}):(\d{2})\z/
        sign = $1 == '-' ? -1 : 1
        sign * ($2.to_i * HOUR_IN_SECONDS + $3.to_i * MINUTE_IN_SECONDS)
      elsif of =~ /\A([+-])(\d{2})(\d{2})?\z/
        sign = $1 == '-' ? -1 : 1
        sign * ($2.to_i * HOUR_IN_SECONDS + ($3 ? $3.to_i * MINUTE_IN_SECONDS : 0))
      else
        0
      end
    else
      0
    end
  end

  # Validate time fields (C: c_valid_time_p)
  def validate_time(h, min, s)
    h += 24 if h < 0
    min += 60 if min < 0
    s += 60 if s < 0
    unless (0..24).cover?(h) && (0..59).cover?(min) && (0..59).cover?(s) &&
           !(h == 24 && (min > 0 || s > 0))
      raise Error, "invalid date"
    end
    [h, min, s]
  end
end
