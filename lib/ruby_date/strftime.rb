# Implementation of ruby/date/ext/date/date_strftime.c
class RubyDate
  # call-seq:
  #   strftime(format = '%F') -> string
  #
  # Returns a string representation of the date in +self+,
  # formatted according the given +format+:
  #
  #   Date.new(2001, 2, 3).strftime # => "2001-02-03"
  #
  # For other formats, see
  # {Formats for Dates and Times}[rdoc-ref:language/strftime_formatting.rdoc].
  def strftime(format = STRFTIME_DEFAULT_FMT)
    # If format is not a string, convert it to a string.
    format = format.to_str unless format.is_a?(String)

    # Check for ASCII compatible encoding.
    raise ArgumentError, "format should have ASCII compatible encoding" unless format.encoding.ascii_compatible?

    # Default format for empty string
    format = STRFTIME_DEFAULT_FMT if format.empty?

    # What to do if format string contains a "\0".
    if format.include?("\0")
      result = String.new
      parts = format.split("\0", -1)

      parts.each_with_index do |part, i|
        result << strftime_format(part) unless part.empty?
        result << "\0" if i < parts.length - 1
      end

      result.force_encoding(format.encoding)

      return result
    end

    # Normal processing without "\0" in format string.
    result = strftime_format(format)
    result.force_encoding(format.encoding)

    result
  end

  private

  def tmx_year
    m_real_year
  end

  def tmx_mon
    mon
  end

  def tmx_mday
    mday
  end

  def tmx_yday
    yday
  end

  def tmx_cwyear
    m_real_cwyear
  end

  def tmx_cweek
    cweek
  end

  def tmx_cwday
    cwday
  end

  def tmx_wday
    wday
  end

  def tmx_wnum0
    # Week number (Sunday start, 00-53)
    m_wnumx(0)
  end

  def tmx_wnum1
    # Week number (Monday start, 00-53)
    m_wnumx(1)
  end

  def tmx_hour
    simple_dat_p? ? 0 : (m_df / 3600).floor
  end

  def tmx_min
    simple_dat_p? ? 0 : ((m_df % 3600) / 60).floor
  end

  def tmx_sec
    simple_dat_p? ? 0 : m_df % 60
  end

  def tmx_sec_fraction
    if simple_dat_p?
      Rational(0, 1)
    else
      # (Decimal part of df) + sf
      df_frac = m_df - m_df.floor
      sf_frac = m_sf == 0 ? 0 : Rational(m_sf, SECOND_IN_NANOSECONDS)
      df_frac + sf_frac
    end
  end

  def tmx_secs
    # C: tmx_m_secs (date_core.c:7306)
    # s = day_to_sec(m_real_jd - UNIX_EPOCH_IN_CJD)
    # if complex: s += m_df
    s = jd_to_unix_time(m_real_jd)
    return s if simple_dat_p?
    df = m_df
    s += df if df != 0
    s
  end

  def tmx_msecs
    # C: tmx_m_msecs (date_core.c:7322)
    # s = tmx_m_secs * 1000
    # if complex: s += m_sf / MILLISECOND_IN_NANOSECONDS
    s = tmx_secs * SECOND_IN_MILLISECONDS
    return s if simple_dat_p?
    sf = m_sf
    s += Rational(sf, SECOND_IN_NANOSECONDS / SECOND_IN_MILLISECONDS) if sf != 0
    s
  end

  def tmx_offset
    simple_dat_p? ? 0 : m_of
  end

  def tmx_zone
    if simple_dat_p? || tmx_offset.zero?
      "+00:00"
    else
      of2str(m_of)
    end
  end

  def of2str(of)
    s, h, m = decode_offset(of)
    sprintf('%c%02d:%02d', s, h, m)
  end

  def decode_offset(of)
    s = (of < 0) ? '-' : '+'
    a = of.abs
    h = a / HOUR_IN_SECONDS
    m = (a % HOUR_IN_SECONDS) / MINUTE_IN_SECONDS
    [s, h, m]
  end

  # Processing format strings.
  def strftime_format(format)
    result = String.new
    i = 0

    while i < format.length
      if format[i] == '%' && i + 1 < format.length
        # Skip '%'
        i += 1

        # Parse flags and width specifiers.
        flags = String.new
        width = String.new
        # E, O, etc. modifiers.
        modifier = nil
        # Number of colons.
        colons = 0

        # Read modifiers (E, O)
        if i < format.length && format[i] =~ /[EO]/
          modifier = format[i]
          i += 1
        end

        # Read colon modifier.
        while i < format.length && format[i] == ':'
          colons += 1
          i += 1
        end

        # Invalid if both the E/O and colon modifiers are present.
        if modifier && colons > 0
          # Invalid combination - just print and continue
          if i < format.length
            spec = format[i]
            result << "%#{modifier}#{':' * colons}#{spec}"
            i += 1
          end
          next
        end

        # Read flags (_-0^#)
        while i < format.length && format[i] =~ /[_\-0^#]/
          flags << format[i]
          i += 1
        end

        # Read width specifier (number)
        while i < format.length && format[i] =~ /[0-9]/
          width << format[i]
          i += 1
        end

        # Width specifier overflow check
        # C: date_strftime.c uses TBUFSIZE (1024) as buffer limit.
        # Width >= 1024 raises ERANGE.
        unless width.empty?
          # If the width is too long (check number of digits)
          if width.length > 10 || (width.length == 10 && width > '2147483647')
            raise Errno::ERANGE, "Result too large"
          end

          width_num = width.to_i

          # C: TBUFSIZE is 1024; padding beyond that overflows the buffer.
          if width_num >= 1024
            raise Errno::ERANGE, "Result too large"
          end
        end

        if i < format.length
          spec = format[i]

          # Check if modifier is a valid specifier.
          if colons > 0
            # Colon modifier is only valid for 'z'.
            if spec == 'z'
              formatted = format_zone_with_colons(colons)
              result << formatted
            else
              # Invalid combination - output as is.
              result << "%#{':' * colons}#{flags}#{width}#{spec}"
            end
          elsif modifier
            valid = case modifier
            when 'E'
              # %E is only valid for c, C, x, X, y, and Y.
              %w[c C x X y Y].include?(spec)
            when 'O'
              # %O is only valid for d, e, H, k, I, l, m, M, S, u, U, V, w, W, and y.
              %w[d e H k I l m M S u U V w W y].include?(spec)
            else
              false
            end

            if valid
              # Valid combination - ignore modifiers and proceed normally.
              formatted = format_spec(spec, flags, width)
              result << formatted
            else
              # Invalid combination - output as is.
              result << "%#{modifier}#{flags}#{width}#{spec}"
            end
          else
            # No modifier - process as usual.
            formatted = format_spec(spec, flags, width)
            result << formatted
          end

          i += 1
        end
      else
        result << format[i]
        i += 1
      end
    end

    result.force_encoding('US-ASCII') if result.ascii_only?

    result
  end

  # Handles format specifiers.
  def format_spec(spec, flags = '', width = '')
    # Get basic formatting results.
    base_result = get_base_format(spec, flags)

    # Apply width specifier.
    if !width.empty?
      width_num = width.to_i
      if spec == 'N'
        # C: %N width is precision (number of fractional digits).
        # Truncate to width_num digits, or zero-pad on right if width_num > 9.
        if width_num <= base_result.length
          base_result[0, width_num]
        else
          base_result.ljust(width_num, '0')
        end
      else
        apply_width(base_result, width_num, flags)
      end
    else
      base_result
    end
  end

  # format specifiers
  def get_base_format(spec, flags = '')
    case spec
    when 'Y' # 4-digit year
      y = tmx_year
      raise Errno::ERANGE, "Result too large" if y.is_a?(Integer) && y.bit_length > 128
      sprintf('%04d', y)
    when 'C' # Century
      sprintf('%02d', tmx_year / 100)
    when 'y' # Two-digit year
      sprintf('%02d', tmx_year % 100)
    when 'm' # Month (01-12)
      sprintf('%02d', tmx_mon)
    when 'B' # Full month name
      MONTHNAMES[tmx_mon] || '?'
    when 'b', 'h' # Abbreviated month name
      (ABBR_MONTHNAMES[tmx_mon] || '?')[0, 3]
    when 'd' # Day (01-31)
      if flags.include?('-')
        # Left-justified (no padding)
        tmx_mday.to_s
      elsif flags.include?('_')
        # Space-padded
        sprintf('%2d', tmx_mday)
      else
        # Zero-padded (default)
        sprintf('%02d', tmx_mday)
      end
    when 'e' # Day (1-31) blank filled
      sprintf('%2d', tmx_mday)
    when 'j' # Day of the year (001-366)
      sprintf('%03d', tmx_yday)
    when 'H' # Hour (00-23)
      if flags.include?('-')
        tmx_hour.to_s
      elsif flags.include?('_')
        sprintf('%2d', tmx_hour)
      else
        sprintf('%02d', tmx_hour)
      end
    when 'k' # Hour (0-23) blank-padded
      sprintf('%2d', tmx_hour)
    when 'I' # Hour (01-12)
      h = tmx_hour % 12
      h = 12 if h.zero?
      if flags.include?('-')
        h.to_s
      elsif flags.include?('_')
        sprintf('%2d', h)
      else
        sprintf('%02d', h)
      end
    when 'l' # Hour (1-12) blank filled
      h = tmx_hour % 12
      h = 12 if h.zero?
      sprintf('%2d', h)
    when 'M' # Minutes (00-59)
      if flags.include?('-')
        tmx_min.to_s
      elsif flags.include?('_')
        sprintf('%2d', tmx_min)
      else
        sprintf('%02d', tmx_min)
      end
    when 'S' # Seconds (00-59)
      if flags.include?('-')
        tmx_sec.to_s
      elsif flags.include?('_')
        sprintf('%2d', tmx_sec)
      else
        sprintf('%02d', tmx_sec)
      end
    when 'L' # Milliseconds (000-999)
      sprintf('%03d', (tmx_sec_fraction * 1000).floor)
    when 'N' # Fractional seconds digits
      # C: width controls precision (number of digits), default 9.
      # %3N → 3 digits (milliseconds), %6N → 6 digits (microseconds),
      # %9N → 9 digits (nanoseconds), %12N → 12 digits (picoseconds, zero-padded).
      # The 'width' variable is handled specially in format_spec for 'N'.
      sprintf('%09d', (tmx_sec_fraction * 1_000_000_000).floor)
    when 'P' # am/pm
      tmx_hour < 12 ? 'am' : 'pm'
    when 'p' # AM/PM
      tmx_hour < 12 ? 'AM' : 'PM'
    when 'A' # Full name of the day of the week
      DAYNAMES[tmx_wday] || '?'
    when 'a' # Abbreviated day of the week
      (ABBR_DAYNAMES[tmx_wday] || '?')[0, 3]
    when 'w' # Day of the week (0-6, Sunday is 0)
      tmx_wday.to_s
    when 'u' # Day of the week (1-7, Monday is 1)
      tmx_cwday.to_s
    when 'U' # Week number (00-53, Sunday start)
      sprintf('%02d', tmx_wnum0)
    when 'W' # Week number (00-53, Monday start)
      sprintf('%02d', tmx_wnum1)
    when 'V' # ISO week number (01-53)
      sprintf('%02d', tmx_cweek)
    when 'G' # ISO week year
      sprintf('%04d', tmx_cwyear)
    when 'g' # ISO week year (2 digits)
      sprintf('%02d', tmx_cwyear % 100)
    when 'z' # Time Zone Offset (+0900)
      format_offset(tmx_offset)
    when 'Z' # Time Zone Name
      tmx_zone || ''
    when 's' # Number of seconds since the Unix epoch
      tmx_secs.to_s
    when 'Q' # Milliseconds since the Unix epoch
      tmx_msecs.to_s
    when 'n' # Line breaks
      "\n"
    when 't' # Tab
      "\t"
    when '%' # % symbol
      '%'
    when 'F' # %Y-%m-%d
      strftime_format('%Y-%m-%d')
    when 'D' # %m/%d/%y
      strftime_format('%m/%d/%y')
    when 'x' # %m/%d/%y
      strftime_format('%m/%d/%y')
    when 'T', 'X' # %H:%M:%S
      strftime_format('%H:%M:%S')
    when 'R' # %H:%M
      strftime_format('%H:%M')
    when 'r' # %I:%M:%S %p
      strftime_format('%I:%M:%S %p')
    when 'c' # %a %b %e %H:%M:%S %Y
      strftime_format('%a %b %e %H:%M:%S %Y')
    when 'v' # %e-%^b-%Y (3-FEB-2001 format)
      day_str = sprintf('%2d', tmx_mday)
      month_str = (ABBR_MONTHNAMES[tmx_mon] || '?')[0, 3].upcase
      year_str = sprintf('%04d', tmx_year)
      "#{day_str}-#{month_str}-#{year_str}"
    when '+' # %a %b %e %H:%M:%S %Z %Y
      strftime_format('%a %b %e %H:%M:%S %Z %Y')
    else
      # Unknown specifiers are output as is.
      "%#{spec}"
    end
  end

  def apply_width(str, width, flags)
    return str if str.length >= width

    # Determine a padding character.
    padding =
      if flags.include?('0')
        '0'
      elsif flags.include?('_')
        ' '
      else
        ' '
      end

    # Left or right justified.
    if flags.include?('-')
      # Left-justified
      str.ljust(width, padding)
    else
      # Right-justified (default)
      str.rjust(width, padding)
    end
  end

  def format_offset(offset)
    return '+0000' if offset.zero?

    sign = offset < 0 ? '-' : '+'
    abs_offset = offset.abs
    hours = abs_offset / 3600
    minutes = (abs_offset % 3600) / 60

    sprintf('%s%02d%02d', sign, hours, minutes)
  end

  def jd_to_unix_time(jd)
    # Unix epoch JD is 2440588 (1970-01-01 00:00:00 UTC).
    # Convert JD to Unix timestamp.
    unix_epoch_jd = 2440588
    (jd - unix_epoch_jd) * DAY_IN_SECONDS
  end

  # Format time zone offset with colon modifier.
  def format_zone_with_colons(colons)
    offset = tmx_offset

    sign = offset < 0 ? '-' : '+'
    abs_offset = offset.abs
    hours = abs_offset / 3600
    minutes = (abs_offset % 3600) / 60
    seconds = abs_offset % 60

    case colons
    when 1
      # %:z -> +hh:mm
      sprintf('%s%02d:%02d', sign, hours, minutes)
    when 2
      # %::z -> +hh:mm:ss
      sprintf('%s%02d:%02d:%02d', sign, hours, minutes, seconds)
    when 3
      # %:::z -> +hh[:mm[:ss]] (Minimum notation)
      if (abs_offset % 3600).zero?
        # +hh
        sprintf('%s%02d', sign, hours)
      elsif (abs_offset % 60).zero?
        # +hh:mm
        sprintf('%s%02d:%02d', sign, hours, minutes)
      else
        # +hh:mm:ss
        sprintf('%s%02d:%02d:%02d', sign, hours, minutes, seconds)
      end
    else
      # No colon (same as %z)
      sprintf('%s%02d%02d', sign, hours, minutes)
    end
  end
end
