# frozen_string_literal: true

require "timeout"

module EnvUtil
  def self.timeout(seconds, &block)
    Timeout.timeout(seconds, &block)
  end
end
