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
    of_sec = utc_offset
    sf = nsec

    nth, ry = RubyDate.send(:decode_year, y, -1)
    rjd, _ = RubyDate.send(:c_civil_to_jd, ry, m, d, RubyDate::GREGORIAN)

    df = h * 3600 + mi * 60 + s

    # Convert local to UTC
    df_utc = df - of_sec
    jd_utc = rjd
    if df_utc < 0
      jd_utc -= 1
      df_utc += 86400
    elsif df_utc >= 86400
      jd_utc += 1
      df_utc -= 86400
    end

    obj = RubyDateTime.send(:new_with_jd_and_time,
                            nth, jd_utc, df_utc, sf, of_sec,
                            RubyDate::GREGORIAN)
    obj.send(:set_sg, RubyDate::ITALY)
    obj
  end unless method_defined?(:to_datetime)
end
