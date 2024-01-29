# frozen_string_literal: true

require_relative "deprecated_methods/version"
require_relative "deprecated_methods/unused_method_checker"
require_relative "deprecated_methods/cli"

module DeprecatedMethods
  class Error < StandardError; end
end
