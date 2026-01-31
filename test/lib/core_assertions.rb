# frozen_string_literal: true

require "stringio"
require "test/unit/assertions"
require "timeout"

module Test
  module Unit
    module CoreAssertions
      include Assertions

      def assert_ractor(code, require: nil)
        omit("Ractor is not supported") unless defined?(Ractor)

        script = +""
        script << "require #{require.inspect}\n" if require
        script << <<~'RUBY'
          unless defined?(RactorAssertions)
            module RactorAssertions
              module_function

              def assert_equal(expected, actual, message = nil)
                raise("assert_equal failed#{": #{message}" if message}") unless expected == actual
              end

              def assert_same(expected, actual, message = nil)
                raise("assert_same failed#{": #{message}" if message}") unless expected.equal?(actual)
              end
            end
          end

          RactorAssertions.module_eval <<-'__RUBY__'
        RUBY
        script << code
        script << <<~'RUBY'
          __RUBY__
        RUBY

        result = Ractor.new(script) do |src|
          eval(src)
          :ok
        end

        take = result.respond_to?(:take) ? :take : :value
        assert_equal(:ok, result.public_send(take))
      end

      def assert_warning(expected)
        warnings = capture_warnings { yield }
        assert(!warnings.empty?, "warning expected but none was issued")
        assert_match(expected, warnings)
      end

      def assert_no_warning
        warnings = capture_warnings { yield }
        assert(warnings.empty?, "warning was issued: #{warnings.inspect}")
      end

      private

      def all_assertions_foreach(*labels)
        errors = []
        labels.each do |label|
          next if label.nil?
          begin
            yield(label)
          rescue Exception => err
            errors << [label, err]
          end
        end

        return if errors.empty?

        messages = errors.map { |label, err| "#{label.inspect}: #{err.message}" }.join(", ")
        raise(errors.first[1].class, messages, errors.first[1].backtrace)
      end

      def capture_warnings
        original = Warning.method(:warn)
        buffer = StringIO.new

        Warning.define_singleton_method(:warn) do |message|
          buffer << message
        end

        yield
        buffer.string
      ensure
        Warning.define_singleton_method(:warn, original)
      end
    end
  end
end
