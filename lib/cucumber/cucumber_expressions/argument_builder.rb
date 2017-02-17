require 'cucumber/cucumber_expressions/argument'

module Cucumber
  module CucumberExpressions
    class ArgumentBuilder
      def self.build_arguments(regexp, text, parameters)
        m = regexp.match(text)
        return nil if m.nil?
        (1...m.length).map do |index|
          value = m[index]
          parameter = parameters[index-1]
          Argument.new(m.offset(index)[0], value, parameter)
        end
      end
    end
  end
end
