# frozen_string_literal: true

class Time
  def to_time
    self
  end unless method_defined?(:to_time)

  def to_date
    y = year
    m = month
    d = day

    nth, ry = RubyDate.send(:decode_year, y, -1)

    # First, create it in GREGORIAN (dates during the reform period are also valid).
    obj = RubyDate.send(:d_simple_new_internal,
                        nth, 0,
                        RubyDate::GREGORIAN,
                        ry, m, d,
                        0x04)  # RubyDate::HAVE_CIVIL

    # Then change to DEFAULT_SG.
    obj.send(:set_sg, RubyDate::ITALY)

    obj
  end unless method_defined?(:to_date)

  def to_datetime
    y = year
    m = month
    d = day
    h = hour
    mi = min
    s = sec
    of = Rational(utc_offset, 86400)
    sf = Rational(nsec, 1_000_000_000)

    RubyDateTime.new(y, m, d, h, mi, s + sf, of, RubyDate::ITALY)
  end unless method_defined?(:to_datetime)
end
