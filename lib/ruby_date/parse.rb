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
      hash = {}

      # JIS X 0301 format
      if str =~ /^([MTSHR])(\d{2})\.(\d{2})\.(\d{2})$/i
        era_char = $1.upcase
        era_year = $2.to_i
        month = $3.to_i
        day = $4.to_i

        era_start = case era_char
                    when 'M' then 1867
                    when 'T' then 1911
                    when 'S' then 1925
                    when 'H' then 1988
                    when 'R' then 2018
                    else 0
                    end

        hash[:year] = era_start + era_year
        hash[:mon] = month
        hash[:mday] = day

        return hash
      end

      # ISO 8601 format
      if str =~ /^(-?\d{4})-(\d{1,2})-(\d{1,2})$/
        hash[:year] = $1.to_i
        hash[:mon] = $2.to_i
        hash[:mday] = $3.to_i
      end

      hash
    end
  end
end
