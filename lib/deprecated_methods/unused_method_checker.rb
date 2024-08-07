# frozen_string_literal: true

require "parser/current"
require "pry"
require "erb"
require "slim"

module DeprecatedMethods
  class UnusedMethodChecker # rubocop:disable Style/Documentation
    attr_accessor :defined_methods, :invoked_methods, :touched_files

    CONTROLLER_METHODS = %w[index edit show destroy new create update].freeze

    def initialize
      @defined_methods = {}
      @invoked_methods = []
      @touched_files = []
    end

    def check_files(files) # rubocop:disable Metrics/AbcSize
      filtered_files = files.select { |file| extension?(file, [".rb", ".erb", ".slim"]) }

      filtered_files.each_with_index do |file, i|
        check_file(file)
        touched_files.push(file)
        sleep(0.1)
        show_progress(i + 1, filtered_files.length)
      end

      invoked_methods = @invoked_methods.compact.flatten.uniq
      defined_methods.reject { |k, _| invoked_methods.include?(k) }
    end

    def generate_html_report(output_file, unused_methods)
      FileUtils.mkdir_p(File.dirname(output_file))
      report_template_path = File.join(File.dirname(__FILE__), "../../assets/report_template.erb")

      File.open(output_file, "w+") do |file|
        file.puts ERB.new(File.read(report_template_path)).result(binding)
      end
    end

    private

    def check_file(file)
      content = File.read(file)
      @current_file = file
      ast = case File.extname(file)
            when ".rb" then parse_ruby_code(content)
            when ".erb" then extract_ruby_code_from_erb(content)
            when ".slim" then extract_ruby_code_from_slim(content)
            end
      extract_method_names(ast, file.include?("_controller"))
      extract_invoked_methods(ast)
    end

    def extract_method_names(node, exclude_controller_methods) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      return unless node.is_a?(Parser::AST::Node)

      case node.send(:type)
      when :def
        method_name = node.children[0].to_s
        return if exclude_controller_methods && CONTROLLER_METHODS.include?(method_name)

        defined_methods[method_name] = @current_file
      when :class, :module
        node.children.each { |child| extract_method_names(child, exclude_controller_methods) }
      else
        if node.respond_to?(:children)
          (node.children || []).each do |child|
            extract_method_names(child, exclude_controller_methods)
          end
        end
      end
    end

    def extract_invoked_methods(node)
      return unless node.is_a?(Parser::AST::Node)

      case node.send(:type)
      when :send
        add_to_invoked_methods(node)
      else
        (node.children || []).each { |child| extract_invoked_methods(child) } if node.respond_to?(:children)
      end
    end

    def extension?(file_path, extensions)
      extensions.include? File.extname(file_path)
    end

    def add_to_invoked_methods(node)
      methods_invoked = defined_methods.keys.select { |k| node.send(:to_sexp).include?(k) }
      invoked_methods.push(methods_invoked) unless methods_invoked.empty?
    end

    def extract_ruby_code_from_erb(erb_code)
      ruby_code = ERB.new(erb_code).src
      parse_ruby_code(ruby_code)
    end

    def extract_ruby_code_from_slim(slim_code)
      ruby_code = Slim::Engine.new.call(slim_code)
      parse_ruby_code(ruby_code)
    end

    def parse_ruby_code(ruby_code)
      buffer = Parser::Source::Buffer.new(File.basename(@current_file))
      buffer.source = ruby_code
      parser = Parser::CurrentRuby.new
      parser.parse(buffer)
    end

    def show_progress(current, total, bar_length = 50)
      current_progress = current.to_f / total
      progress = current_progress * bar_length
      print "\r[#{"=" * progress.floor}#{" " * (bar_length - progress.floor)}] #{current_progress.round(2)}%"
      $stdout.flush
    end
  end
end
