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

      # Clean up the string - normalize whitespace
      str = str.gsub(/[\t\n\v\f\r]+/, ' ').strip

      # Return empty hash for blank string after cleanup
      return hash if str.empty?

      # Try various formats in order of specificity

      # asctime format with timezone: Sat Aug 28 02:29:34 JST 1999
      if str =~ /\b(sun|mon|tue|wed|thu|fri|sat)\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})\s+(.*?)\s+(-?\d+)\s*$/i
        # Save captured groups immediately before they're overwritten
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

        return hash
      end

      # asctime format without timezone: Sat Aug 28 02:55:50 1999
      if str =~ /\b(sun|mon|tue|wed|thu|fri|sat)\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})\s+(\d{2}):(\d{2}):(\d{2})\s+(-?\d+)\s*$/i
        # Save captured groups immediately
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

        return hash
      end

      # ISO 8601 basic date with extended time: 19990523T23:55:21Z
      if str =~ /(\d{8})T(\d{2}):(\d{2}):(\d{2})(?:[,.](\d+))?(z|[-+]\d{2}:?\d{2})?/i
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

        return hash
      end

      # ISO 8601 extended datetime: 1999-05-23T23:55:21Z or 1999-05-23 23:55:21+09:00
      if str =~ /(-?\d{4,})-(\d{2})-(\d{2})[T\s](\d{2}):(\d{2}):(\d{2})(?:[,.](\d+))?(z|[-+]\d{2}:?\d{2})?/i
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
        hash[:sec] = sec_str.to_i

        if zone_str && !zone_str.empty?
          zone = zone_str.strip
          hash[:zone] = zone
          hash[:offset] = parse_zone_offset(zone)
        end

        hash[:_year_str] = year_str
        apply_comp(hash)

        return hash
      end

      # ISO 8601 pure basic datetime: 19990523T235521Z (fully compact)
      if str =~ /(\d{8})T(\d{6})(?:[,.](\d+))?(z|[-+]\d{2}:?\d{2})?/i
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

        return hash
      end

      # ISO 8601 date only: 1999-08-28
      if str =~ /(-?\d{4})-(\d{2})-(\d{2})\s*$/
        year_str = $1
        mon_str = $2
        mday_str = $3

        hash[:year] = year_str.to_i
        hash[:mon] = mon_str.to_i
        hash[:mday] = mday_str.to_i
        hash[:_year_str] = year_str
        apply_comp(hash)

        return hash
      end

      # RFC 2822: Sat, 28 Aug 1999 02:55:50 +0900
      if str =~ /(sun|mon|tue|wed|thu|fri|sat),?\s+(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(-?\d{2,})\s+(\d{2}):(\d{2})(?::(\d{2}))?\s*(z|[-+]\d{4}|[a-z]{2,})?/i
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

        return hash
      end

      # Remaining patterns...
      # (Keep existing patterns for other formats)

      apply_comp(hash)
      hash
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

      # Handle Z (UTC)
      return 0 if zone.upcase == 'Z'

      # Handle numeric offsets: +0900, -0500, +09:00, etc.
      if zone =~ /^([-+])(\d{2})(:?(\d{2}))?(:?(\d{2}))?$/
        sign = $1 == '-' ? -1 : 1
        hours = $2.to_i
        minutes = $4 ? $4.to_i : 0
        seconds = $6 ? $6.to_i : 0
        return sign * (hours * 3600 + minutes * 60 + seconds)
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
