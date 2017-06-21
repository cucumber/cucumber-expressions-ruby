require 'cucumber/cucumber_expressions/parameter_type'
require 'cucumber/cucumber_expressions/errors'
require 'cucumber/cucumber_expressions/cucumber_expression_generator'

module Cucumber
  module CucumberExpressions
    class ParameterTypeRegistry
      INTEGER_REGEXPS = [/-?\d+/, /\d+/]
      FLOAT_REGEXP = /-?\d*\.?\d+/
      WORD_REGEXP = /\w+/

      def initialize
        @parameter_type_by_name = {}
        @parameter_type_by_class = {}
        @parameter_types_by_regexp = Hash.new {|hash, regexp| hash[regexp] = []}

        define_parameter_type(ParameterType.new('int', INTEGER_REGEXPS, Integer, lambda {|s| s.to_i}, true, true))
        define_parameter_type(ParameterType.new('float', FLOAT_REGEXP, Float, lambda {|s| s.to_f}, false, true))
        define_parameter_type(ParameterType.new('word', WORD_REGEXP, String, lambda {|s| s}, false, false))
      end

      def lookup_by_type(clazz)
        @parameter_type_by_class[clazz]
      end

      def lookup_by_type_name(name)
        @parameter_type_by_name[name]
      end

      def lookup_by_regexp(parameter_type_regexp, expression_regexp, text)
        parameter_types = @parameter_types_by_regexp[parameter_type_regexp]
        return nil if parameter_types.nil?
        if parameter_types.length > 1 && !parameter_types[0].prefer_for_regexp_match?
          # We don't do this check on insertion because we only want to restrict
          # ambiguity when we look up by Regexp. Users of CucumberExpression should
          # not be restricted.
          generated_expressions = CucumberExpressionGenerator.new(self).generate_expressions(text)
          raise AmbiguousParameterTypeError.new(parameter_type_regexp, expression_regexp, parameter_types, generated_expressions)
        end
        parameter_types.first
      end

      def parameter_types
        @parameter_type_by_name.values
      end

      def define_parameter_type(parameter_type)
        put(@parameter_type_by_class, parameter_type.type, parameter_type, "type")
        put(@parameter_type_by_name, parameter_type.name, parameter_type, "name")

        parameter_type.regexps.each do |parameter_type_regexp|
          parameter_types = @parameter_types_by_regexp[parameter_type_regexp]
          if parameter_types.any? && parameter_types[0].prefer_for_regexp_match? && parameter_type.prefer_for_regexp_match?
            raise CucumberExpressionError.new("There can only be one prefer_for_regexp_match parameter type per regexp. The regexp /#{parameter_type_regexp}/ is used for two prefer_for_regexp_match parameter types, {#{parameter_types[0].name}} and {#{parameter_type.name}}")
          end
          parameter_types.push(parameter_type)
          parameter_types.sort!
        end
      end

      def put(map, key, parameter, prop)
        if map.has_key?(key)
          raise CucumberExpressionError.new("There is already a parameter with #{prop} #{key}")
        end
        map[key] = parameter
      end
    end
  end
end
