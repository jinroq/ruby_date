# frozen_string_literal: true

class RubyDate
  # TIME_PAT
  # Regular expression pattern for C's parse_time.
  # $1: Entire time portion
  # $2: Time zone portion (optional)
  #
  # (?-i:[[:alpha:]]) in the zone portion means "case-sensitive, alphabetic characters only." In Ruby, you can achieve the same effect by writing
  # [A-Za-z] inside (?-i:...).
  TIME_PAT = /
    (                                   # $1: whole time
      \d+\s*                            #   hour (required)
      (?:
        (?:                             #   Branch A: colon-separated
          :\s*\d+                       #     :min
          (?:                           #
            \s*:\s*\d+(?:[,.]\d*)?      #       :sec[.frac]
          )?                            #
        |                               #   Branch B: h\/m\/s separated
          h(?:\s*\d+m?                  #     h[min[m]
            (?:\s*\d+s?)?               #           [sec[s]]]
          )?                            #
        )                               #
        (?:                             #   AM\/PM suffix (optional)
          \s*[ap](?:m\b|\.m\.)          #
        )?                              #
      |                                 #   Branch C: Only AM\/PM
        [ap](?:m\b|\.m\.)               #
      )                                 #
    )                                   #
    (?:                                 # Time Zone (optional)
      \s*                               #
      (                                 # $2: Across time zones
        (?:gmt|utc?)?[-+]\d+            #   Numeric Offset
        (?:[,.:]\d+(?::\d+)?)?          #     Optional decimals\/minutes\/seconds
      |                                 #
        [A-Za-z.\s]+                    #   "Eastern standard time" etc.
        (?:standard|daylight)\stime\b   #
      |                                 #
        [A-Za-z]+(?:\sdst)?\b           #   "EST" / "EST dst" etc.
      )                                 #
    )?                                  #
  /xi

  private_constant :TIME_PAT

  # Parse $1 (the time string) further and set hash to hour/min/sec/sec_fraction.
  #
  # Internal pattern:
  #   $1 hour
  #   $2 min   (colon format)
  #   $3 sec   (colon format)
  #   $4 frac  ([,.]\d*)
  #   $5 min   (h format)
  #   $6 sec   (h format)
  #   $7 am/pm (a or p)
  TIME_DETAIL_PAT = /
    \A(\d+)\s*                          # $1 hour
    (?:
      :\s*(\d+)                         # $2 min (colon)
      (?:\s*:\s*(\d+)([,.]\d*)?)?       # $3 sec, $4 frac (colon)
    |
      h(?:\s*(\d+)m?                    # $5 min (h)
        (?:\s*(\d+)s?)?                 # $6 sec (h)
      )?                                #
    )?
    (?:\s*([ap])(?:m\b|\.m\.))?         # $7 am/pm
  /xi

  private_constant :TIME_DETAIL_PAT

  # era1: AD, A.D.
  # BEGIN_ERA = \b
  # END_ERA  = (?!(?<!\.)[a-z])
  #   Does not match if the next character is lowercase and is not immediately preceded by a "."
  #   = Prevents accidental matches in the middle of a word.
  ERA1_PAT = /\b(a(?:d\b|\.d\.))(?!(?<!\.)[a-z])/i
  private_constant :ERA1_PAT

  # era2: CE, C.E., BC, B.C., BCE, B.C.E.
  ERA2_PAT = /\b(c(?:e\b|\.e\.)|b(?:ce\b|\.c\.e\.)|b(?:c\b|\.c\.))(?!(?<!\.)[a-z])/i
  private_constant :ERA2_PAT

  # Pattern structure:
  #   $1: mday (optional leading apostrophe with '?)
  #       [^-\d\s]* to remove ordinal suffixes, commas, and dots
  #   $2: mon (full name or abbreviation, case insensitive)
  #       [^-\d\s']* to remove delimiters after the month name
  #   $3: era (options: AD/A.D./CE/C.E./BC/B.C./BCE/B.C.E.)
  #   $4: year (optional: optional ordinal suffix with '?-?\d+)
  PARSE_EU_PAT = /
    ('?\d+)                             # $1 mday
    [^-\d\s]*                           #     Separator after mday (ordinal number, comma, etc.)
    \s*                                 #
    (january|february|march|april|may|june|   # $2 mon
     july|august|september|october|november|december|
     jan|feb|mar|apr|jun|jul|aug|sep|oct|nov|dec)
    [^-\d\s']*                          #     Separator after mon
    (?:                                 #   Year section (optional)
      \s*                               #
      (?:                               #     Era symbol (optional)
        \b                              #       BEGIN_ERA
        (c(?:e|\.e\.)|b(?:ce|\.c\.e\.)| #       $3 era
         a(?:d|\.d\.)|b(?:c|\.c\.))     #
        (?!(?<!\.)[a-z])                #       END_ERA
      )?                                #
      \s*                               #
      ('?-?\d+(?:(?:st|nd|rd|th)\b)?)   #       $4 year
    )?                                  #
  /xi

  private_constant :PARSE_EU_PAT

  # Pattern construction:
  #   $1: mon (full name or abbreviation)
  #       [^-\d\s']* absorbs the separator after the month name
  #   $2: mday ('? for optional leading apostrophe)
  #       [^-\d\s']* absorbs the ordinal suffix and separator
  #   $3: era (options: AD/A.D./CE/C.E./BC/B.C./BCE/B.C.E.)
  #   $4: year (options: '?-?\d+)
  #
  # C's "\s*+,?" is a possessive quantifier, but Ruby does not have possessive.
  # \s*,? works equivalently (same amount of backtracking).
  PARSE_US_PAT = /
    \b                                  #   Word Boundaries
    (january|february|march|april|may|june|   # $1 mon
     july|august|september|october|november|december|
     jan|feb|mar|apr|jun|jul|aug|sep|oct|nov|dec)
    [^-\d\s']*                          #     Separator after mon
    \s*                                 #
    ('?\d+)                             # $2 mday
    [^-\d\s']*                          #     Separator after mday (ordinal number, etc.)
    (?:                                 #   Year section (optional)
      \s*,?                             #     Comma (optional)
      \s*                               #
      (?:                               #     Era symbol (optional)
        \b                              #       BEGIN_ERA
        (c(?:e|\.e\.)|b(?:ce|\.c\.e\.)| #       $3 era
         a(?:d|\.d\.)|b(?:c|\.c\.))     #
        (?!(?<!\.)[a-z])                #       END_ERA
      )?                                #
      \s*                               #
      ('?-?\d+)                         #       $4 year
    )?                                  #
  /xi

  private_constant :PARSE_US_PAT

  # Pattern structure:
  #   $1: year ('?[-+]?\d+ apostrophe/sign optional)
  #   $2: mon (\d+)
  #   $3: mday ('?-?\d+ apostrophe/minus optional)
  PARSE_ISO_PAT = /('?[-+]?\d+)-(\d+)-('?-?\d+)/
  private_constant :PARSE_ISO_PAT

  # Pattern structure:
  #   $1: cwyear (2 or 4 digits, optional)
  #   $2: cweek  (2 digits, required)
  #   $3: cwday  (1 digit, optional)
  PARSE_ISO21_PAT = /\b(\d{2}|\d{4})?-?w(\d{2})(?:-?(\d))?\b/i
  private_constant :PARSE_ISO21_PAT

  # Pattern structure:
  #   $1: cwday (1 digit)
  PARSE_ISO22_PAT = /-w-(\d)\b/i
  private_constant :PARSE_ISO22_PAT

  # Pattern structure:
  #   $1: mon  (2 digits, optional)
  #   $2: mday (2 digits, required)
  PARSE_ISO23_PAT = /--(\d{2})?-(\d{2})\b/
  private_constant :PARSE_ISO23_PAT

  # Pattern structure:
  #   $1: mon  (2 digits, required)
  #   $2: mday (2 digits, optional)
  PARSE_ISO24_PAT = /--(\d{2})(\d{2})?\b/
  private_constant :PARSE_ISO24_PAT

  # Pattern structure:
  #   $1: year (2 or 4 digits, required)
  #   $2: yday (3 digits, required)
  #
  # Exclusion pattern: [,.]YYYY-DDD is a year-day with a decimal point, not a date
  PARSE_ISO25_PAT0 = /[,.](\d{2}|\d{4})-\d{3}\b/
  PARSE_ISO25_PAT  = /\b(\d{2}|\d{4})-(\d{3})\b/
  private_constant :PARSE_ISO25_PAT0, :PARSE_ISO25_PAT

  # Pattern structure:
  #   $1: yday (3 digits, required)
  #
  # Exclusion pattern: \d-DDD is year-day, processed by a separate parser
  PARSE_ISO26_PAT0 = /\d-\d{3}\b/
  PARSE_ISO26_PAT  = /\b-(\d{3})\b/
  private_constant :PARSE_ISO26_PAT0, :PARSE_ISO26_PAT

  # Pattern structure:
  #   $1: Era symbol (single character: [mtshr], /i ignores case)
  #   $2: Year (year number within the era)
  #   $3: Month
  #   $4: Day
  PARSE_JIS_PAT = /\b([#{JISX0301_ERA_INITIALS}])(\d+)\.(\d+)\.(\d+)/i
  private_constant :PARSE_JIS_PAT

  # Pattern structure:
  #   $1: mday ('?-?\d+)
  #   $2: mon (month abbreviation or full name)
  #       [^-/.]* to remove the separator after the month name (excluding "-", "/", and ".")
  #   $3: year ('?-?\d+)
  PARSE_VMS11_PAT = /
    ('?-?\d+)                           # $1 mday
    -(january|february|march|april|may|june|   # $2 mon
      july|august|september|october|november|december|
      jan|feb|mar|apr|jun|jul|aug|sep|oct|nov|dec)
    [^-/.]*                             #    Separator after mon (excluding "-/.")
    -('?-?\d+)                          # $3 year
  /xi
  private_constant :PARSE_VMS11_PAT

  # Pattern structure:
  #   $1: mon (month abbreviation or full name)
  #       [^-/.]* to remove delimiters after the month name (excluding "-", "/", and ".")
  #   $2: mday ('?-?\d+)
  #   $3: year ('?-?\d+ optional)
  PARSE_VMS12_PAT = /
    \b                                  #   Word Boundaries
    (january|february|march|april|may|june|   # $1 mon
      july|august|september|october|november|december|
      jan|feb|mar|apr|jun|jul|aug|sep|oct|nov|dec)
    [^-/.]*                             #    Separator after mon (excluding "-/.")
    -('?-?\d+)                          # $2 mday
    (?:-('?-?\d+))?                     # $3 year (optional)
  /xi
  private_constant :PARSE_VMS12_PAT

  # Pattern structure:
  #   $1: First number  ('?-?\d+ optional apostrophe/minus)
  #   /                 slash separator
  #   $2: Second number ('?\d+ optional apostrophe)
  #   $3: Third number  ('?-?\d+ optional)
  #       \D absorbs "one non-numeric character" as a separator
  #       => Anything can be a separator, such as "/", "-", or " "
  PARSE_SLA_PAT = /('?-?\d+)\/\s*('?\d+)(?:\D\s*('?-?\d+))?/
  private_constant :PARSE_SLA_PAT

  # Pattern structure:
  #   $1: First number  ('?-?\d + optional apostrophe minus)
  #   \.                Dot separator + optional space
  #   $2: Second number ('?\d + optional apostrophe)
  #   \.                Dot separator + optional space
  #   $3: Third number  ('?-?\d + optional apostrophe minus)
  PARSE_DOT_PAT = /('?-?\d+)\.\s*('?\d+)\.\s*('?-?\d+)/
  private_constant :PARSE_DOT_PAT

  # Pattern structure:
  #   Requires a leading ' (apostrophe)
  #   $1: Number string (one or more digits)
  #   Use \b to check for word boundaries (numbers not followed by word characters)
  PARSE_YEAR_PAT = /'(\d+)\b/
  private_constant :PARSE_YEAR_PAT

  # Pattern construction:
  #   \b checks for word boundaries
  #   $1: Month abbreviation (jan-dec, case insensitive)
  #   \S* absorbs trailing non-whitespace characters
  PARSE_MON_PAT = /\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\S*/i
  private_constant :PARSE_MON_PAT

  # Pattern structure:
  #   $1: Numeric string (one or more digits)
  #   $2: Ordinal suffix (st, nd, rd, th, case-insensitive)
  #   Check for word boundaries with \b
  PARSE_MDAY_PAT = /(\d+)(st|nd|rd|th)\b/i
  private_constant :PARSE_MDAY_PAT

  # Pattern structure:
  #   $1: Sign ([-+]?, optional)
  #   $2: Main digits (2-14 digits)
  #   $3: Time digits (2-6 digits, optional)
  #   $4: Fractional part (optional)
  #   $5: Time zone (z, [-+]\d{1,4}, [\d...], optional)
  PARSE_DDD_PAT = /
    ([-+]?)                    # $1 sign
    (\d{2,14})                 # $2 main number string
    (?:                        # time portion (optional)
      \s*
      t?                       # "t" option (ISO 8601 date and time separator)
      \s*
      (\d{2,6})?               # $3 time digit string
      (?:[,.](\d*))?           # $4 decimal part
    )?
    (?:                        # zone part (optional)
      \s*
      (                        # $5 zone
        z\b                    #   "z" (UTC)
      |
        [-+]\d{1,4}\b          #   numeric offset (e.g. +0900)
      |
        \[[-+]?\d[^\]]*\]      #   bracketed zones (e.g., [+09:00])
      )
    )?
  /xi
end
