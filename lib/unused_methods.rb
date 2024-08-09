# frozen_string_literal: true

require_relative "unused_methods/version"
require_relative "unused_methods/unused_method_checker"
require_relative "unused_methods/cli"

module UnusedMethods
  class << self
    attr_accessor :prefix, default: "vscode://file/"
  end
  class Error < StandardError; end
end
