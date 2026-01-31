# frozen_string_literal: true

require 'test/unit'
require_relative '../../lib/ruby_date'

class RubyDateDateParseRactorTest < Test::Unit::TestCase
  def code(klass = RubyDate, share: false)
    <<~RUBY.gsub('RubyDate', klass.name)
      share = #{share}
      d = RubyDate.parse('Aug 23:55')
      Ractor.make_shareable(d) if share
      d2, d3 = Ractor.new(d) { |d| [d, RubyDate.parse(d.to_s)] }.value
      if share
        assert_same d, d2
      else
        assert_equal d, d2
      end
      assert_equal d, d3
    RUBY
  end

  def test_date_ractor
    assert_ractor(code                       , require: 'date')
    assert_ractor(code(          share: true), require: 'date')
    assert_ractor(code(RubyDate             ), require: 'date')
    assert_ractor(code(RubyDate, share: true), require: 'date')
  end
end
