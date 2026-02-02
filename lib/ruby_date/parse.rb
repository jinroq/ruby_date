# frozen_string_literal: true

# Implementation of ruby/date/ext/date/date_parse.c
class RubyDate
  class << self
    # call-seq:
    #   Date.parse(string = '-4712-01-01', comp = true, start = Date::ITALY, limit: 128) -> date
    #
    # Returns a new \Date object with values parsed from +string+.
    #
    # If +comp+ is +true+ and the given year is in the range <tt>(0..99)</tt>,
    # the current century is supplied; otherwise, the year is taken as given.
    #
    # See argument {start}[rdoc-ref:language/calendars.rdoc@Argument+start].
    # See argument {limit}[rdoc-ref:Date@Argument+limit].
    #
    # Related: Date._parse (returns a hash).
    def parse(string = JULIAN_EPOCH_DATE, comp = true, start = DEFAULT_SG, limit: 128)
      str = string.to_s.strip
      sg = start

      # JIS X 0301 format (e.g., M06.01.01, H31.04.30, R01.05.01)
      if str =~ /^([MTSHR])(\d{2})\.(\d{2})\.(\d{2})$/i
        era_char = $1.upcase
        era_year = $2.to_i
        month = $3.to_i
        day = $4.to_i

        # Convert era year to gregorian year
        era_start = case era_char
                    when 'M' then 1867  # Meiji
                    when 'T' then 1911  # Taisho
                    when 'S' then 1925  # Showa
                    when 'H' then 1988  # Heisei
                    when 'R' then 2018  # Reiwa
                    else 0
                    end

        year = era_start + era_year

        return new(year, month, day, sg)
      end

      # ISO 8601 format (YYYY-MM-DD)
      if str =~ /^(-?\d{4})-(\d{1,2})-(\d{1,2})$/
        year = $1.to_i
        month = $2.to_i
        day = $3.to_i

        return new(year, month, day, sg)
      end

      # Fallback to default
      new(-4712, 1, 1, sg)
    end

    # call-seq:
    #   Date._parse(string, comp = true, limit: 128) -> hash
    #
    # Returns a hash of values parsed from +string+.
    #
    # If +comp+ is +true+ and the given year is in the range <tt>(0..99)</tt>,
    # the current century is supplied; otherwise, the year is taken as given.
    #
    # See argument {limit}[rdoc-ref:Date@Argument+limit].
    #
    # Related: Date.parse (returns a \Date object).
    def _parse(string, comp = true, limit: 128)
      str = string.to_s.strip

      # Check limit
      if limit && str.length > limit
        raise ArgumentError, "string length (#{str.length}) exceeds the limit #{limit}"
      end

      date__parse(str, comp)
    end

    private

    def date__parse(str, comp)
      hash = {}
      hash[:_comp] = comp
      hash[:_year_str] = nil

      # Return empty hash for nil or empty string
      return hash if str.nil? || str.empty?

      # Clean up the string - normalize whitespace and remove null bytes
      str = str.gsub(/[\t\n\v\f\r\0]+/, ' ').strip

      # Return empty hash for blank string after cleanup
      return hash if str.empty?

      # Try various formats in order of specificity
      return hash if parse_asctime_with_zone(str, hash)
      return hash if parse_asctime(str, hash)
      return hash if parse_dot(str, hash)
      return hash if parse_iso_extended_datetime(str, hash)
      return hash if parse_iso_basic_date_with_ext_time(str, hash)
      return hash if parse_iso_basic_datetime(str, hash)
      return hash if parse_iso_basic_datetime_6digit(str, hash)
      return hash if parse_iso_basic_mmddthhmm(str, hash)
      return hash if parse_iso_basic_dd_hhmm(str, hash)
      return hash if parse_iso_basic_mmdd_hhmm(str, hash)
      return hash if parse_iso_basic_datetime_with_space(str, hash)
      return hash if parse_iso_basic_dd(str, hash)
      return hash if parse_iso_basic_mmdd(str, hash)
      return hash if parse_iso_basic_date_only(str, hash)
      return hash if parse_iso_date_only(str, hash)
      return hash if parse_rfc2822(str, hash)
      return hash if parse_rfc850(str, hash)
      return hash if parse_reversed_iso(str, hash)
      return hash if parse_jisx0301(str, hash)
      return hash if parse_ddd(str, hash)

      apply_comp(hash)

      hash
    end

    # asctime format with timezone: Sat Aug 28 02:29:34 JST 1999
    def parse_asctime_with_zone(str, hash)
      return false unless str =~ /\b(sun|mon|tue|wed|thu|fri|sat)\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})\s+(.*?)\s+(-?\d+)\s*$/i

      wday_str = $1
      mon_str = $2
      mday_str = $3
      hour_str = $4
      min_str = $5
      sec_str = $6
      zone_part = $7
      year_str = $8

      hash[:wday] = day_num(wday_str)
      hash[:mon] = mon_num(mon_str)
      hash[:mday] = mday_str.to_i
      hash[:hour] = hour_str.to_i
      hash[:min] = min_str.to_i
      hash[:sec] = sec_str.to_i

      zone_part = zone_part.strip
      unless zone_part.empty?
        zone = zone_part.gsub(/\s+/, ' ')
        hash[:zone] = zone
        hash[:offset] = parse_zone_offset(zone)
      end

      hash[:_year_str] = year_str
      hash[:year] = year_str.to_i
      apply_comp(hash)

      true
    end

    # asctime format without timezone: Sat Aug 28 02:55:50 1999
    def parse_asctime(str, hash)
      return false unless str =~ /\b(sun|mon|tue|wed|thu|fri|sat)\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})\s+(-?\d+)\s*$/i

      wday_str = $1
      mon_str = $2
      mday_str = $3
      hour_str = $4
      min_str = $5
      sec_str = $6
      year_str = $7

      hash[:wday] = day_num(wday_str)
      hash[:mon] = mon_num(mon_str)
      hash[:mday] = mday_str.to_i
      hash[:hour] = hour_str.to_i
      hash[:min] = min_str.to_i
      hash[:sec] = sec_str.to_i
      hash[:_year_str] = year_str
      hash[:year] = year_str.to_i
      apply_comp(hash)

      true
    end

    # Dot-separated date: 1999.5.2 or 1999.05.02 23:55:21
    def parse_dot(str, hash)
      # Dot-separated date with time: 1999.5.2 23:55:21
      if str =~ /^(\d{2,4})\.(\d{1,2})\.(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})$/
        year_str = $1
        mon_str = $2
        mday_str = $3
        hour_str = $4
        min_str = $5
        sec_str = $6

        hash[:year] = year_str.to_i
        hash[:mon] = mon_str.to_i
        hash[:mday] = mday_str.to_i
        hash[:hour] = hour_str.to_i
        hash[:min] = min_str.to_i
        hash[:sec] = sec_str.to_i

        hash[:_year_str] = year_str
        apply_comp(hash)

        return true
      end

      # Dot-separated date only: 1999.5.2
      if str =~ /^(\d{2,4})\.(\d{1,2})\.(\d{1,2})\s*$/
        year_str = $1
        mon_str = $2
        mday_str = $3

        hash[:year] = year_str.to_i
        hash[:mon] = mon_str.to_i
        hash[:mday] = mday_str.to_i

        hash[:_year_str] = year_str
        apply_comp(hash)

        return true
      end

      false
    end

    # ISO 8601 extended datetime: 1999-05-23T23:55:21Z or 2000-01-31 13:20 M
    def parse_iso_extended_datetime(str, hash)
      return false unless str =~ /([-+]?\d{2,})-(\d{2})-(\d{2})[T\s](\d{2}):(\d{2})(?::(\d{2}))?(?:[,.](\d+))?\s*(z|[a-z]|[-+]\d{1,2}(?:[.,]\d+)?(?::?\d{2})?)?/i

      year_str = $1
      mon_str = $2
      mday_str = $3
      hour_str = $4
      min_str = $5
      sec_str = $6
      frac_str = $7
      zone_str = $8

      hash[:year] = year_str.to_i
      hash[:mon] = mon_str.to_i
      hash[:mday] = mday_str.to_i
      hash[:hour] = hour_str.to_i
      hash[:min] = min_str.to_i
      hash[:sec] = sec_str.to_i if sec_str

      if zone_str && !zone_str.empty?
        zone = zone_str.strip
        hash[:zone] = zone
        hash[:offset] = parse_zone_offset(zone)
      end

      hash[:_year_str] = year_str
      apply_comp(hash)

      true
    end

    # ISO 8601 basic date with extended time: 19990523T23:55:21Z
    def parse_iso_basic_date_with_ext_time(str, hash)
      return false unless str =~ /^(\d{8})T(\d{2}):(\d{2}):(\d{2})(?:[,.](\d+))?(z|[-+]\d{1,2}(?::?\d{2})?)?$/i

      date_part = $1
      hour_str = $2
      min_str = $3
      sec_str = $4
      frac_str = $5
      zone_str = $6

      year_str = date_part[0, 4]
      mon_str = date_part[4, 2]
      mday_str = date_part[6, 2]

      hash[:year] = year_str.to_i
      hash[:mon] = mon_str.to_i
      hash[:mday] = mday_str.to_i
      hash[:hour] = hour_str.to_i
      hash[:min] = min_str.to_i
      hash[:sec] = sec_str.to_i

      if zone_str && !zone_str.empty?
        zone = zone_str.strip
        hash[:zone] = zone
        hash[:offset] = parse_zone_offset(zone)
      end

      hash[:_year_str] = year_str
      apply_comp(hash)

      true
    end

    # ISO 8601 pure basic datetime: 19990523T235521Z (fully compact)
    def parse_iso_basic_datetime(str, hash)
      return false unless str =~ /(\d{8})T(\d{6})(?:[,.](\d+))?(z|[-+]\d{2}:?\d{2})?/i

      date_part = $1
      time_part = $2
      frac_str = $3
      zone_str = $4

      year_str = date_part[0, 4]
      mon_str = date_part[4, 2]
      mday_str = date_part[6, 2]

      hour_str = time_part[0, 2]
      min_str = time_part[2, 2]
      sec_str = time_part[4, 2]

      hash[:year] = year_str.to_i
      hash[:mon] = mon_str.to_i
      hash[:mday] = mday_str.to_i
      hash[:hour] = hour_str.to_i
      hash[:min] = min_str.to_i
      hash[:sec] = sec_str.to_i

      if zone_str && !zone_str.empty?
        zone = zone_str.strip
        hash[:zone] = zone
        hash[:offset] = parse_zone_offset(zone)
      end

      hash[:_year_str] = year_str
      apply_comp(hash)

      true
    end

    # ISO 8601 pure basic datetime: 990523T235521 (YYMMDDTHHMMSS, 6 digits + 6 digits)
    def parse_iso_basic_datetime_6digit(str, hash)
      return false unless str =~ /^(\d{6})T(\d{6})(?:[,.](\d+))?(z|[-+]\d{2}:?\d{2})?$/i

      date_part = $1
      time_part = $2
      frac_str = $3
      zone_str = $4

      year_str = date_part[0, 2]
      mon_str = date_part[2, 2]
      mday_str = date_part[4, 2]

      hour_str = time_part[0, 2]
      min_str = time_part[2, 2]
      sec_str = time_part[4, 2]

      hash[:year] = year_str.to_i
      hash[:mon] = mon_str.to_i
      hash[:mday] = mday_str.to_i
      hash[:hour] = hour_str.to_i
      hash[:min] = min_str.to_i
      hash[:sec] = sec_str.to_i

      if zone_str && !zone_str.empty?
        zone = zone_str.strip
        hash[:zone] = zone
        hash[:offset] = parse_zone_offset(zone)
      end

      hash[:_year_str] = year_str
      apply_comp(hash)

      true
    end

    # ISO 8601 basic: MMDDTHHMM (no year, no seconds, with optional timezone)
    def parse_iso_basic_mmddthhmm(str, hash)
      return false unless str =~ /^(\d{4})T(\d{4})(z|[-+]\d{2}:?\d{2})?$/i

      date_part = $1
      time_part = $2
      zone_str = $3

      hash[:mon] = date_part[0, 2].to_i
      hash[:mday] = date_part[2, 2].to_i
      hash[:hour] = time_part[0, 2].to_i
      hash[:min] = time_part[2, 2].to_i

      if zone_str && !zone_str.empty?
        zone = zone_str.strip
        hash[:zone] = zone
        hash[:offset] = parse_zone_offset(zone)
      end

      true
    end

    # ISO 8601 basic: DD HHMM (day and time only)
    def parse_iso_basic_dd_hhmm(str, hash)
      return false unless str =~ /^(\d{2})\s+(\d{4})$/

      hash[:mday] = $1.to_i
      hash[:hour] = $2[0, 2].to_i
      hash[:min] = $2[2, 2].to_i

      true
    end

    # ISO 8601 basic: MMDD HHMM (no year, no seconds)
    def parse_iso_basic_mmdd_hhmm(str, hash)
      return false unless str =~ /^(\d{4})\s+(\d{4})$/

      date_part = $1
      time_part = $2

      hash[:mon] = date_part[0, 2].to_i
      hash[:mday] = date_part[2, 2].to_i
      hash[:hour] = time_part[0, 2].to_i
      hash[:min] = time_part[2, 2].to_i

      true
    end

    # ISO 8601 basic datetime with space: 19990523 235521 or 990523 235521
    def parse_iso_basic_datetime_with_space(str, hash)
      return false unless str =~ /^(\d{6,8})\s+(\d{6})$/

      date_part = $1
      time_part = $2

      if date_part.length == 8
        # YYYYMMDD HHMMSS
        year_str = date_part[0, 4]
        mon_str = date_part[4, 2]
        mday_str = date_part[6, 2]
      else
        # YYMMDD HHMMSS
        year_str = date_part[0, 2]
        mon_str = date_part[2, 2]
        mday_str = date_part[4, 2]
      end

      hour_str = time_part[0, 2]
      min_str = time_part[2, 2]
      sec_str = time_part[4, 2]

      hash[:year] = year_str.to_i
      hash[:mon] = mon_str.to_i
      hash[:mday] = mday_str.to_i
      hash[:hour] = hour_str.to_i
      hash[:min] = min_str.to_i
      hash[:sec] = sec_str.to_i

      hash[:_year_str] = year_str
      apply_comp(hash)

      true
    end

    # ISO 8601 basic: day only (DD) - 2 digits
    def parse_iso_basic_dd(str, hash)
      return false unless str =~ /^(\d{2})\s*$/ && str.length == 2

      hash[:mday] = $1.to_i

      true
    end

    # ISO 8601 basic date: MMDD (4 digits, no year)
    def parse_iso_basic_mmdd(str, hash)
      return false unless str =~ /^(\d{2})(\d{2})\s*$/ && str.length == 4

      hash[:mon] = $1.to_i
      hash[:mday] = $2.to_i

      true
    end

    # ISO 8601 basic date: YYMMDD (6 digits) or YYYYMMDD (8+ digits) - date only
    def parse_iso_basic_date_only(str, hash)
      return false unless (str.length == 6 || str.length == 8) && str =~ /^([-+]?\d{2,})(\d{2})(\d{2})\s*$/

      year_str = $1
      mon_str = $2
      mday_str = $3

      hash[:year] = year_str.to_i
      hash[:mon] = mon_str.to_i
      hash[:mday] = mday_str.to_i
      hash[:_year_str] = year_str
      apply_comp(hash)

      true
    end

    # ISO 8601 date only: 1999-08-28 or +011985-04-12 or 02-04-12 (2-digit year allowed)
    def parse_iso_date_only(str, hash)
      return false unless str =~ /([-+]?\d{2,})-(\d{2})-(\d{2})\s*$/

      year_str = $1
      mon_str = $2
      mday_str = $3

      hash[:year] = year_str.to_i
      hash[:mon] = mon_str.to_i
      hash[:mday] = mday_str.to_i
      hash[:_year_str] = year_str
      apply_comp(hash)

      true
    end

    # RFC 2822: Sun, 22 Aug 1999 00:45:29 GMT
    def parse_rfc2822(str, hash)
      return false unless str =~ /(sun|mon|tue|wed|thu|fri|sat),?\s*(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(-?\d{2,})\s+(\d{2}):(\d{2})(?::(\d{2}))?(?:\s+([a-z]+(?:\s+[a-z]+)*|z|[-+]\d{2,4}))?/i

      wday_str = $1
      mday_str = $2
      mon_str = $3
      year_str = $4
      hour_str = $5
      min_str = $6
      sec_str = $7
      zone_str = $8

      hash[:wday] = day_num(wday_str)
      hash[:mday] = mday_str.to_i
      hash[:mon] = mon_num(mon_str)
      hash[:_year_str] = year_str
      hash[:year] = year_str.to_i
      hash[:hour] = hour_str.to_i
      hash[:min] = min_str.to_i
      hash[:sec] = sec_str.to_i if sec_str

      if zone_str && !zone_str.empty?
        zone = zone_str.strip
        hash[:zone] = zone
        hash[:offset] = parse_zone_offset(zone)
      end

      apply_comp(hash)

      true
    end

    # RFC 850 (obsoleted by RFC 1036): Tuesday, 02-Mar-99 11:20:32 GMT
    def parse_rfc850(str, hash)
      return false unless str =~ /(sunday|monday|tuesday|wednesday|thursday|friday|saturday),?\s+(\d{1,2})-(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)-(\d{2,4})\s+(\d{2}):(\d{2})(?::(\d{2}))?\s+([a-z]+(?:\s+[a-z]+)*|z|[-+]\d{2,4})?/i

      wday_str = $1
      mday_str = $2
      mon_str = $3
      year_str = $4
      hour_str = $5
      min_str = $6
      sec_str = $7
      zone_str = $8

      hash[:wday] = day_num(wday_str)
      hash[:mday] = mday_str.to_i
      hash[:mon] = mon_num(mon_str)
      hash[:_year_str] = year_str
      hash[:year] = year_str.to_i
      hash[:hour] = hour_str.to_i
      hash[:min] = min_str.to_i
      hash[:sec] = sec_str.to_i if sec_str

      if zone_str && !zone_str.empty?
        zone = zone_str.strip
        hash[:zone] = zone
        hash[:offset] = parse_zone_offset(zone)
      end

      apply_comp(hash)

      true
    end

    # Reversed ISO 8601 (European format): DD-MM-YYYY or DD-MM-YY
    def parse_reversed_iso(str, hash)
      return false unless str =~ /^(\d{1,2})-(\d{1,2})-('?-?\d{2,})(?:\s+(\d{2}):(\d{2}):(\d{2}))?$/

      mday_str = $1
      mon_str = $2
      year_str = $3
      hour_str = $4
      min_str = $5
      sec_str = $6

      hash[:mday] = mday_str.to_i
      hash[:mon] = mon_str.to_i

      # Handle year with optional apostrophe and sign
      is_negative = year_str.start_with?('-')
      year_str = year_str.sub(/^'/, '')
      year_str = year_str.sub(/^-/, '')

      year = year_str.to_i
      year = -year if is_negative

      hash[:year] = year
      hash[:_year_str] = year_str

      if hour_str
        hash[:hour] = hour_str.to_i
        hash[:min] = min_str.to_i
        hash[:sec] = sec_str.to_i
      end

      apply_comp(hash)

      true
    end

    # JIS X 0301 format: M11.05.23 or H31.04.30T23:55:21+09:00
    def parse_jisx0301(str, hash)
      return false unless str =~ /^([MTSHR])(\d{2})\.(\d{2})\.(\d{2})(?:[T\s](\d{2}):(\d{2}):(\d{2})(?:[,.](\d+))?)?\s*(z|[-+]\d{2}:?\d{2})?$/i

      era_char = $1.upcase
      era_year = $2.to_i
      mon = $3.to_i
      mday = $4.to_i
      hour = $5
      min = $6
      sec = $7
      frac = $8
      zone = $9

      # Convert era year to gregorian year
      era_start = case era_char
                  when 'M' then 1867  # Meiji
                  when 'T' then 1911  # Taisho
                  when 'S' then 1925  # Showa
                  when 'H' then 1988  # Heisei
                  when 'R' then 2018  # Reiwa
                  else 0
                  end

      hash[:year] = era_start + era_year
      hash[:mon] = mon
      hash[:mday] = mday

      if hour
        hash[:hour] = hour.to_i
        hash[:min] = min.to_i
        hash[:sec] = sec.to_i
        hash[:sec_fraction] = Rational(frac.to_i, 10 ** frac.length) if frac
      end

      if zone && !zone.empty?
        hash[:zone] = zone
        hash[:offset] = parse_zone_offset(zone)
      end

      true
    end

    def parse_ddd(str, hash)
      pattern = /^([-+]?)(\d{2,14})(?:\s*t?\s*(\d{2,6})?(?:[,.](\d*))?)?\s*(z|[-+]\d{1,4}|\[[-+]?\d[^\]]*\])?$/i

      m = str.match(pattern)
      return false if m.nil?

      sign = m[1]
      digits = m[2]
      time_digits = m[3]
      fraction = m[4]
      zone = m[5]

      l = digits.length

      case l
      when 2
        if time_digits.nil? && !fraction.nil?
          hash[:sec] = digits[-2, 2].to_i
        else
          hash[:mday] = digits[0, 2].to_i
        end
      when 4
        if time_digits.nil? && !fraction.nil?
          hash[:sec] = digits[-2, 2].to_i
          hash[:min] = digits[-4, 2].to_i
        else
          hash[:mon] = digits[0, 2].to_i
          hash[:mday] = digits[2, 2].to_i
        end
      when 6
        if time_digits.nil? && !fraction.nil?
          hash[:sec] = digits[-2, 2].to_i
          hash[:min] = digits[-4, 2].to_i
          hash[:hour] = digits[-6, 2].to_i
        else
          y = digits[0, 2].to_i
          y = -y if sign == '-'
          hash[:year] = y
          hash[:mon] = digits[2, 2].to_i
          hash[:mday] = digits[4, 2].to_i
          hash[:_year_str] = digits[0, 2]
        end
      when 8, 10, 12, 14
        if time_digits.nil? && !fraction.nil?
          hash[:sec] = digits[-2, 2].to_i
          hash[:min] = digits[-4, 2].to_i
          hash[:hour] = digits[-6, 2].to_i
          hash[:mday] = digits[-8, 2].to_i
          hash[:mon] = digits[-10, 2].to_i if l >= 10
          if l == 12
            y = digits[-12, 2].to_i
            y = -y if sign == '-'
            hash[:year] = y
            hash[:_year_str] = digits[-12, 2]
          elsif l == 14
            y = digits[-14, 4].to_i
            y = -y if sign == '-'
            hash[:year] = y
            hash[:_comp] = false
          end
        else
          y = digits[0, 4].to_i
          y = -y if sign == '-'
          hash[:year] = y
          hash[:mon] = digits[4, 2].to_i
          hash[:mday] = digits[6, 2].to_i
          hash[:hour] = digits[8, 2].to_i if l >= 10
          hash[:min] = digits[10, 2].to_i if l >= 12
          hash[:sec] = digits[12, 2].to_i if l >= 14
          hash[:_comp] = false
        end
      when 3
        if time_digits.nil? && !fraction.nil?
          hash[:sec] = digits[-2, 2].to_i
          hash[:min] = digits[-3, 1].to_i
        else
          hash[:yday] = digits[0, 3].to_i
        end
      when 5
        if time_digits.nil? && !fraction.nil?
          hash[:sec] = digits[-2, 2].to_i
          hash[:min] = digits[-4, 2].to_i
          hash[:hour] = digits[-5, 1].to_i
        else
          y = digits[0, 2].to_i
          y = -y if sign == '-'
          hash[:year] = y
          hash[:yday] = digits[2, 3].to_i
          hash[:_year_str] = digits[0, 2]
        end
      when 7
        if time_digits.nil? && !fraction.nil?
          hash[:sec] = digits[-2, 2].to_i
          hash[:min] = digits[-4, 2].to_i
          hash[:hour] = digits[-6, 2].to_i
          hash[:mday] = digits[-7, 1].to_i
        else
          y = digits[0, 4].to_i
          y = -y if sign == '-'
          hash[:year] = y
          hash[:yday] = digits[4, 3].to_i
        end
      end

      # Processing the time portion
      if time_digits && !time_digits.empty?
        tl = time_digits.length
        if !fraction.nil?
          case tl
          when 2, 4, 6
            hash[:sec] = time_digits[-2, 2].to_i
            hash[:min] = time_digits[-4, 2].to_i if tl >= 4
            hash[:hour] = time_digits[-6, 2].to_i if tl >= 6
          end
        else
          case tl
          when 2, 4, 6
            hash[:hour] = time_digits[0, 2].to_i
            hash[:min] = time_digits[2, 2].to_i if tl >= 4
            hash[:sec] = time_digits[4, 2].to_i if tl >= 6
          end
        end
      end

      # Handling fractional seconds
      if fraction && !fraction.empty?
        hash[:sec_fraction] = Rational(fraction.to_i, 10 ** fraction.length)
      end

      # Handling timezone
      if zone && !zone.empty?
        clean_zone = zone.gsub(/[\[\]]/, '')

        # Handle [-5:EST] format: offset:timezone_name
        if clean_zone =~ /^([-+]?\d+(?:\.\d+)?):(.+)$/
          offset_part = $1
          zone_name = $2
          hash[:zone] = zone_name
          hash[:offset] = parse_zone_offset("[#{offset_part}]")
        else
          hash[:zone] = clean_zone
          hash[:offset] = parse_zone_offset(zone)
        end
      end

      true
    end

    # Parse HTTP date format
    def date__httpdate(str)
      hash = {}

      # Return empty hash for nil or empty string
      return hash if str.nil? || str.empty?

      # Try type 1: "Sat, 03 Feb 2001 00:00:00 GMT"
      return hash if httpdate_type1(str, hash)

      # Try type 2: "Saturday, 03-Feb-01 00:00:00 GMT"
      return hash if httpdate_type2(str, hash)

      # Try type 3: "Sat Feb  3 00:00:00 2001"
      return hash if httpdate_type3(str, hash)

      hash
    end

    # Parse ISO 8601 format
    def date__iso8601(str)
      hash = {}

      # Return empty hash for nil or empty string
      return hash if str.nil? || str.empty?

      # Try extended datetime format: 2001-02-03T04:05:06
      return hash if iso8601_ext_datetime(str, hash)

      # Try basic datetime format: 20010203T040506
      return hash if iso8601_bas_datetime(str, hash)

      # Try extended time format: 04:05:06
      return hash if iso8601_ext_time(str, hash)

      # Try basic time format: 040506
      return hash if iso8601_bas_time(str, hash)

      hash
    end

    # Parse JIS X 0301 format
    def date__jisx0301(str)
      hash = {}

      # Return empty hash for nil or empty string
      return hash if str.nil? || str.empty?

      # Try JIS X 0301 format first
      return hash if jisx0301(str, hash)

      # Fallback to ISO 8601 format
      date__iso8601(str)
    end

    # HTTP date type 1: "Sat, 03 Feb 2001 00:00:00 GMT"
    def httpdate_type1(str, hash)
      pattern = /\A\s*#{ABBR_DAYS_PATTERN}\s*,\s+
                (\d{2})\s+
                #{ABBR_MONTHS_PATTERN}\s+
                (-?\d{4})\s+
                (\d{2}):(\d{2}):(\d{2})\s+
                (gmt)\s*\z/ix

      match = pattern.match(str)
      return false unless match

      hash[:wday] = day_num(match[1])
      hash[:mday] = match[2].to_i
      hash[:mon] = mon_num(match[3])
      hash[:year] = match[4].to_i
      hash[:hour] = match[5].to_i
      hash[:min] = match[6].to_i
      hash[:sec] = match[7].to_i
      hash[:zone] = match[8]
      hash[:offset] = 0

      true
    end

    # HTTP date type 2: "Saturday, 03-Feb-01 00:00:00 GMT"
    def httpdate_type2(str, hash)
      pattern = /\A\s*#{DAYS_PATTERN}\s*,\s+
                (\d{2})\s*-\s*
                #{ABBR_MONTHS_PATTERN}\s*-\s*
                (\d{2})\s+
                (\d{2}):(\d{2}):(\d{2})\s+
                (gmt)\s*\z/ix

      match = pattern.match(str)
      return false unless match

      hash[:wday] = day_num(match[1])
      hash[:mday] = match[2].to_i
      hash[:mon] = mon_num(match[3])

      # Year completion for 2-digit year
      year = match[4].to_i
      year = comp_year69(year) if year >= 0 && year <= 99
      hash[:year] = year

      hash[:hour] = match[5].to_i
      hash[:min] = match[6].to_i
      hash[:sec] = match[7].to_i
      hash[:zone] = match[8]
      hash[:offset] = 0

      true
    end

    # HTTP date type 3: "Sat Feb  3 00:00:00 2001"
    def httpdate_type3(str, hash)
      pattern = /\A\s*#{ABBR_DAYS_PATTERN}\s+
                #{ABBR_MONTHS_PATTERN}\s+
                (\d{1,2})\s+
                (\d{2}):(\d{2}):(\d{2})\s+
                (\d{4})\s*\z/ix

      match = pattern.match(str)
      return false unless match

      hash[:wday] = day_num(match[1])
      hash[:mon] = mon_num(match[2])
      hash[:mday] = match[3].to_i
      hash[:hour] = match[4].to_i
      hash[:min] = match[5].to_i
      hash[:sec] = match[6].to_i
      hash[:year] = match[7].to_i

      true
    end

    # Helper: Convert day name to number (0=Sunday, 6=Saturday)
    def day_num(day_name)
      abbr_days = %w[sun mon tue wed thu fri sat]
      abbr_days.index(day_name[0, 3].downcase) || 0
    end

    # Helper: Convert month name to number (1=January, 12=December)
    def mon_num(month_name)
      abbr_months = %w[jan feb mar apr may jun jul aug sep oct nov dec]
      (abbr_months.index(month_name[0, 3].downcase) || 0) + 1
    end

    # Helper: Complete 2-digit year (69-99 -> 1900s, 00-68 -> 2000s)
    def comp_year69(year)
      year >= 69 ? year + 1900 : year + 2000
    end

    # ISO 8601 extended datetime: 2001-02-03T04:05:06+09:00
    def iso8601_ext_datetime(str, hash)
      pattern = /\A\s*
        (?:
          ([-+]?\d{2,}|-)-(\d{2})?(?:-(\d{2}))?|      # YYYY-MM-DD or --MM-DD
          ([-+]?\d{2,})?-(\d{3})|                     # YYYY-DDD
          (\d{4}|\d{2})?-w(\d{2})-(\d)|               # YYYY-Www-D
          -w-(\d)                                     # -W-D
        )
        (?:t
          (\d{2}):(\d{2})(?::(\d{2})(?:[,.](\d+))?)?  # HH:MM:SS.fraction
          (z|[-+]\d{2}(?::?\d{2})?)?                  # timezone
        )?
      \s*\z/ix

      match = pattern.match(str)
      return false unless match

      # Calendar date (YYYY-MM-DD)
      if match[1]
        unless match[1] == '-'
          year = match[1].to_i
          # Complete 2-digit year
          year = comp_year69(year) if match[1].length < 4
          hash[:year] = year
        end
        hash[:mon] = match[2].to_i if match[2]
        hash[:mday] = match[3].to_i if match[3]
      # Ordinal date (YYYY-DDD)
      elsif match[5]
        if match[4]
          year = match[4].to_i
          year = comp_year69(year) if match[4].length < 4
          hash[:year] = year
        end
        hash[:yday] = match[5].to_i
      # Week date (YYYY-Www-D)
      elsif match[8]
        if match[6]
          year = match[6].to_i
          year = comp_year69(year) if match[6].length < 4
          hash[:cwyear] = year
        end
        hash[:cweek] = match[7].to_i
        hash[:cwday] = match[8].to_i
      # Week day only (-W-D)
      elsif match[9]
        hash[:cwday] = match[9].to_i
      end

      # Time
      if match[10]
        hash[:hour] = match[10].to_i
        hash[:min] = match[11].to_i
        hash[:sec] = match[12].to_i if match[12]
        hash[:sec_fraction] = parse_fraction(match[13]) if match[13]
      end

      # Timezone
      if match[14]
        hash[:zone] = match[14]
        hash[:offset] = parse_zone_offset(match[14])
      end

      true
    end

    # ISO 8601 basic datetime: 20010203T040506
    def iso8601_bas_datetime(str, hash)
      # Try full basic datetime: YYYYMMDD or YYMMDD
      pattern = /\A\s*
        ([-+]?(?:\d{4}|\d{2})|--)  # Year (YYYY, YY, --, or signed)
        (\d{2}|-)                  # Month (MM or -)
        (\d{2})                    # Day (DD)
        (?:t?
          (\d{2})(\d{2})           # Hour and minute (HHMM)
          (?:(\d{2})               # Second (SS)
            (?:[,.](\d+))?         # Fraction
          )?
          (z|[-+]\d{2}(?:\d{2})?)? # Timezone
        )?
      \s*\z/ix

      match = pattern.match(str)
      if match
        # Calendar date
        unless match[1] == '--'
          year = match[1].to_i
          year = comp_year69(year) if match[1].length == 2 && match[1] !~ /^[-+]/
          hash[:year] = year
        end
        hash[:mon] = match[2].to_i unless match[2] == '-'
        hash[:mday] = match[3].to_i

        # Time
        if match[4]
          hash[:hour] = match[4].to_i
          hash[:min] = match[5].to_i
          hash[:sec] = match[6].to_i if match[6]
          hash[:sec_fraction] = parse_fraction(match[7]) if match[7]
        end

        # Timezone
        if match[8]
          hash[:zone] = match[8]
          hash[:offset] = parse_zone_offset(match[8])
        end

        return true
      end

      # Try ordinal date: YYYYDDD or YYDDD
      pattern = /\A\s*
        ([-+]?(?:\d{4}|\d{2}))      # Year
        (\d{3})                     # Day of year
        (?:t?
          (\d{2})(\d{2})            # Hour and minute
          (?:(\d{2})                # Second
            (?:[,.](\d+))?          # Fraction
          )?
          (z|[-+]\d{2}(?:\d{2})?)?  # Timezone
        )?
      \s*\z/ix

      match = pattern.match(str)
      if match
        year = match[1].to_i
        year = comp_year69(year) if match[1].length == 2 && match[1] !~ /^[-+]/
        hash[:year] = year
        hash[:yday] = match[2].to_i

        # Time
        if match[3]
          hash[:hour] = match[3].to_i
          hash[:min] = match[4].to_i
          hash[:sec] = match[5].to_i if match[5]
          hash[:sec_fraction] = parse_fraction(match[6]) if match[6]
        end

        # Timezone
        if match[7]
          hash[:zone] = match[7]
          hash[:offset] = parse_zone_offset(match[7])
        end

        return true
      end

      # Try -DDD (ordinal without year)
      pattern = /\A\s*
        -(\d{3})                 # Day of year
        (?:t?
          (\d{2})(\d{2})         # Hour and minute
          (?:(\d{2})             # Second
            (?:[,.](\d+))?       # Fraction
          )?
          (z|[-+]\d{2}(?:\d{2})?)?  # Timezone
        )?
      \s*\z/ix

      match = pattern.match(str)
      if match
        hash[:yday] = match[1].to_i

        # Time
        if match[2]
          hash[:hour] = match[2].to_i
          hash[:min] = match[3].to_i
          hash[:sec] = match[4].to_i if match[4]
          hash[:sec_fraction] = parse_fraction(match[5]) if match[5]
        end

        # Timezone
        if match[6]
          hash[:zone] = match[6]
          hash[:offset] = parse_zone_offset(match[6])
        end

        return true
      end

      # Try week date: YYYYWwwD or YYWwwD
      pattern = /\A\s*
        (\d{4}|\d{2})            # Year
        w(\d{2})                 # Week
        (\d)                     # Day of week
        (?:t?
          (\d{2})(\d{2})         # Hour and minute
          (?:(\d{2})             # Second
            (?:[,.](\d+))?       # Fraction
          )?
          (z|[-+]\d{2}(?:\d{2})?)?  # Timezone
        )?
      \s*\z/ix

      match = pattern.match(str)
      if match
        year = match[1].to_i
        year = comp_year69(year) if match[1].length == 2
        hash[:cwyear] = year
        hash[:cweek] = match[2].to_i
        hash[:cwday] = match[3].to_i

        # Time
        if match[4]
          hash[:hour] = match[4].to_i
          hash[:min] = match[5].to_i
          hash[:sec] = match[6].to_i if match[6]
          hash[:sec_fraction] = parse_fraction(match[7]) if match[7]
        end

        # Timezone
        if match[8]
          hash[:zone] = match[8]
          hash[:offset] = parse_zone_offset(match[8])
        end

        return true
      end

      # Try -WwwD (week date without year)
      pattern = /\A\s*
        -w(\d{2})                # Week
        (\d)                     # Day of week
        (?:t?
          (\d{2})(\d{2})         # Hour and minute
          (?:(\d{2})             # Second
            (?:[,.](\d+))?       # Fraction
          )?
          (z|[-+]\d{2}(?:\d{2})?)?  # Timezone
        )?
      \s*\z/ix

      match = pattern.match(str)
      if match
        hash[:cweek] = match[1].to_i
        hash[:cwday] = match[2].to_i

        # Time
        if match[3]
          hash[:hour] = match[3].to_i
          hash[:min] = match[4].to_i
          hash[:sec] = match[5].to_i if match[5]
          hash[:sec_fraction] = parse_fraction(match[6]) if match[6]
        end

        # Timezone
        if match[7]
          hash[:zone] = match[7]
          hash[:offset] = parse_zone_offset(match[7])
        end

        return true
      end

      # Try -W-D (day of week only)
      pattern = /\A\s*
        -w-(\d)                  # Day of week
        (?:t?
          (\d{2})(\d{2})         # Hour and minute
          (?:(\d{2})             # Second
            (?:[,.](\d+))?       # Fraction
          )?
          (z|[-+]\d{2}(?:\d{2})?)?  # Timezone
        )?
      \s*\z/ix

      match = pattern.match(str)
      if match
        hash[:cwday] = match[1].to_i

        # Time
        if match[2]
          hash[:hour] = match[2].to_i
          hash[:min] = match[3].to_i
          hash[:sec] = match[4].to_i if match[4]
          hash[:sec_fraction] = parse_fraction(match[5]) if match[5]
        end

        # Timezone
        if match[6]
          hash[:zone] = match[6]
          hash[:offset] = parse_zone_offset(match[6])
        end

        return true
      end

      false
    end

    # ISO 8601 extended time: 04:05:06+09:00
    def iso8601_ext_time(str, hash)
      # Pattern: HH:MM:SS.fraction or HH:MM:SS,fraction
      pattern = /\A\s*(\d{2}):(\d{2})(?::(\d{2})(?:[,.](\d+))?)?(z|[-+]\d{2}(?::?\d{2})?)?\s*\z/ix

      match = pattern.match(str)
      return false unless match

      hash[:hour] = match[1].to_i
      hash[:min] = match[2].to_i
      hash[:sec] = match[3].to_i if match[3]
      hash[:sec_fraction] = parse_fraction(match[4]) if match[4]

      if match[5]
        hash[:zone] = match[5]
        hash[:offset] = parse_zone_offset(match[5])
      end

      true
    end

    # ISO 8601 basic time: 040506
    def iso8601_bas_time(str, hash)
      # Pattern: HHMMSS.fraction or HHMMSS,fraction
      pattern = /\A\s*(\d{2})(\d{2})(?:(\d{2})(?:[,.](\d+))?)?(z|[-+]\d{2}(?:\d{2})?)?\s*\z/ix

      match = pattern.match(str)
      return false unless match

      hash[:hour] = match[1].to_i
      hash[:min] = match[2].to_i
      hash[:sec] = match[3].to_i if match[3]
      hash[:sec_fraction] = parse_fraction(match[4]) if match[4]

      if match[5]
        hash[:zone] = match[5]
        hash[:offset] = parse_zone_offset(match[5])
      end

      true
    end

    # Parse fractional seconds
    def parse_fraction(frac_str)
      return nil unless frac_str
      Rational(frac_str.to_i, 10 ** frac_str.length)
    end

    # Parse timezone offset (Z, +09:00, -0500, etc.)
    def parse_zone_offset(zone_str)
      return nil if zone_str.nil? || zone_str.empty?

      zone = zone_str.strip

      # Handle [+9] or [-9] or [9 ] format (brackets around offset)
      if zone =~ /^\[(.*)\]$/
        zone = $1.strip
      end

      # Handle Z (UTC)
      return 0 if zone.upcase == 'Z'

      # Handle unsigned numeric offset: 9, 09 (assume positive)
      if zone =~ /^(\d{1,2})$/
        hours = $1.to_i
        return hours * 3600
      end

      # Handle simple numeric offsets with sign: +9, -9, +09, -05, etc.
      if zone =~ /^([-+])(\d{1,2})$/
        sign = $1 == '-' ? -1 : 1
        hours = $2.to_i
        return sign * (hours * 3600)
      end

      # Handle +09:00, -05:30 format (with colon)
      if zone =~ /^([-+])(\d{2}):(\d{2})$/
        sign = $1 == '-' ? -1 : 1
        hours = $2.to_i
        minutes = $3.to_i
        return sign * (hours * 3600 + minutes * 60)
      end

      # Handle +0900, -0500 format (4 digits, no colon)
      if zone =~ /^([-+])(\d{4})$/
        sign = $1 == '-' ? -1 : 1
        hours = $2[0, 2].to_i
        minutes = $2[2, 2].to_i
        return sign * (hours * 3600 + minutes * 60)
      end

      # Handle +0900 format (4 digits without colon)
      if zone =~ /^([-+])(\d{4})$/
        sign = $1 == '-' ? -1 : 1
        hours = $2[0, 2].to_i
        minutes = $2[2, 2].to_i
        return sign * (hours * 3600 + minutes * 60)
      end

      # Handle fractional hours: +9.5, -5.5
      if zone =~ /^([-+])(\d+)[.,](\d+)$/
        sign = $1 == '-' ? -1 : 1
        hours = $2.to_i
        fraction = "0.#{$3}".to_f
        return sign * ((hours + fraction) * 3600).to_i
      end

      # Handle GMT+9, GMT-5, etc.
      if zone =~ /^(?:gmt|utc)?([-+])(\d{1,2})(?::?(\d{2}))?(?::?(\d{2}))?$/i
        sign = $1 == '-' ? -1 : 1
        hours = $2.to_i
        minutes = $3 ? $3.to_i : 0
        seconds = $4 ? $4.to_i : 0
        return sign * (hours * 3600 + minutes * 60 + seconds)
      end

      # Known timezone abbreviations
      zone_offsets = {
        'JST' => 9 * 3600,
        'GMT' => 0,
        'UTC' => 0,
        'UT' => 0,
        'EST' => -5 * 3600,
        'EDT' => -4 * 3600,
        'CST' => -6 * 3600,
        'CDT' => -5 * 3600,
        'MST' => -7 * 3600,
        'MDT' => -6 * 3600,
        'PST' => -8 * 3600,
        'PDT' => -7 * 3600,
        'AEST' => 10 * 3600,
        'MET DST' => 2 * 3600,
        'GMT STANDARD TIME' => 0,
        'MOUNTAIN STANDARD TIME' => -7 * 3600,
        'MOUNTAIN DAYLIGHT TIME' => -6 * 3600,
        'MEXICO STANDARD TIME' => -6 * 3600,
        'E. AUSTRALIA STANDARD TIME' => 10 * 3600,
        'W. CENTRAL AFRICA STANDARD TIME' => 1 * 3600,
      }

      # Handle military timezones (single letters A-Z except J)
      if zone =~ /^([A-Z])$/i
        letter = zone.upcase
        return 0 if letter == 'Z'
        return nil if letter == 'J'  # J is not used

        if letter <= 'I'
          # A-I: +1 to +9
          offset = letter.ord - 'A'.ord + 1
        elsif letter >= 'K' && letter <= 'M'
          # K-M: +10 to +12 (skip J)
          offset = letter.ord - 'A'.ord  # K is 10th letter (ord-'A'=10)
        elsif letter >= 'N' && letter <= 'Y'
          # N-Y: -1 to -12
          offset = -(letter.ord - 'N'.ord + 1)
        else
          return nil
        end

        return offset * 3600
      end

      # Normalize zone string for lookup
      zone_upper = zone.gsub(/\s+/, ' ').upcase
      zone_offsets[zone_upper]
    end

    # JIS X 0301 format: H13.02.03 or H13.02.03T04:05:06
    def jisx0301(str, hash)
      # Pattern: [Era]YY.MM.DD[T]HH:MM:SS[.fraction][timezone]
      # Era initials: M, T, S, H, R (or none for ISO 8601 fallback)
      pattern = /\A\s*
        ([#{JISX0301_ERA_INITIALS}])?  # Era (optional)
        (\d{2})\.(\d{2})\.(\d{2})      # YY.MM.DD
        (?:t                            # Time separator (optional)
          (?:
            (\d{2}):(\d{2})             # HH:MM
            (?::(\d{2})                 # :SS (optional)
              (?:[,.](\d*))?            # .fraction (optional)
            )?
            (z|[-+]\d{2}(?::?\d{2})?)?  # timezone (optional)
          )?
        )?
      \s*\z/ix

      match = pattern.match(str)
      return false unless match

      # Parse era and year
      era_char = match[1] ? match[1].upcase : JISX0301_DEFAULT_ERA
      era_year = match[2].to_i

      # Convert era year to gregorian year
      era_start = gengo(era_char)
      hash[:year] = era_start + era_year

      # Parse month and day
      hash[:mon] = match[3].to_i
      hash[:mday] = match[4].to_i

      # Parse time (if present)
      if match[5]
        hash[:hour] = match[5].to_i
        hash[:min] = match[6].to_i if match[6]
        hash[:sec] = match[7].to_i if match[7]
        hash[:sec_fraction] = parse_fraction(match[8]) if match[8]
      end

      # Parse timezone (if present)
      if match[9]
        hash[:zone] = match[9]
        hash[:offset] = parse_zone_offset(match[9])
      end

      true
    end

    # Convert era character to year offset
    def gengo(era_char)
      case era_char.upcase
      when 'M' then 1867  # Meiji
      when 'T' then 1911  # Taisho
      when 'S' then 1925  # Showa
      when 'H' then 1988  # Heisei
      when 'R' then 2018  # Reiwa
      else 0
      end
    end

    def apply_comp(hash)
      if hash[:_comp] && hash[:year] && hash[:_year_str]
        year = hash[:year]
        year_str = hash[:_year_str].sub(/^-/, '')

        if year_str.length == 2 && year >= 0 && year <= 99
          hash[:year] = year >= 69 ? year + 1900 : year + 2000
        end
      end

      hash.delete(:_comp)
      hash.delete(:_year_str)
    end
  end
end
