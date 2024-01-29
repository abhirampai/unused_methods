require 'parser/current'
require 'rugged'
require 'pry'


module DeprecatedMethods
  class UnusedMethodChecker
    attr_accessor :defined_methods, :invoked_methods, :touched_files

    CONTROLLER_METHODS = ["index", "edit", "show", "destroy", "new", "create", "update"]

    def initialize
      @defined_methods = {}
      @invoked_methods = []
      @touched_files = []
    end

    def check_files(files)
      files.each do |file|
        next unless has_extension?(file, ".rb")
        check_file(file)
        touched_files.push(file)
        print(".")
      end

      invoked_methods = @invoked_methods.compact.flatten.uniq
      defined_methods.reject { |k, _| invoked_methods.include?(k) }
    end

    def generate_html_report(output_file, unused_methods)
      FileUtils.mkdir_p(File.dirname(output_file))
      report_template_path = File.join(File.dirname(__FILE__), '../../assets/report_template.erb')

      File.open(output_file, 'w+') do |file|
        file.puts ERB.new(File.read(report_template_path)).result(binding)
      end
    end

    private

    def check_file(file)
      content = File.read(file)
      @current_file = file
      ast = Parser::CurrentRuby.parse(content)
      extract_method_names(ast, file.include?("_controller"))
      extract_invoked_methods(ast)
    end

    def extract_method_names(node, exclude_controller_methods)
      if node.is_a?(Parser::AST::Node)
        case node.send(:type)
        when :def      
          method_name = node.children[0].to_s
          return if exclude_controller_methods && CONTROLLER_METHODS.include?(method_name)

          defined_methods[method_name] = @current_file
        when :class, :module
          node.children.each { |child| extract_method_names(child, exclude_controller_methods) }
        else
          (node.children || []).each { |child| extract_method_names(child, exclude_controller_methods) } if node.respond_to?(:children)
        end
      end
    end

    def extract_invoked_methods(node)
      if node.is_a?(Parser::AST::Node)
        case node.send(:type)
        when :send
          add_to_invoked_methods(node)
        else
          (node.children || []).each { |child| extract_invoked_methods(child) } if node.respond_to?(:children)
        end
      end
    end

    def has_extension?(file_path, extension)
      File.extname(file_path) == extension
    end

    def add_to_invoked_methods(node)
      methods_invoked = defined_methods.keys.select { |k| node.send(:to_sexp).include?(k) }
      invoked_methods.push(methods_invoked) unless methods_invoked.empty?
    end
  end
end