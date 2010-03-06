require 'heist'

# TODO fix this in Heist itself
class Heist::Runtime::Binding
  def to_ruby
    expression.to_ruby
  end
end

module CukeMacros
  class << self
    
    include Cucumber::Ast
    SCENARIO_TAGS = [:scenario, :scenario_outline]
    
    def load(path)
      runtime.load(path)
    end
    
    def rewrite(feature_element)
      sexp = feature_element.to_sexp
      tags = filter_tags(sexp)
      cons = Heist.parse(sexp)
      
      applicable_macro = tags.map { |t| runtime[t] rescue nil }.compact.first
      return feature_element unless applicable_macro
      
      rewrite = applicable_macro.call(runtime.top_level, cons).expression.to_ruby
      rewrite = inject_tags(rewrite, tags)
      
      element = feature_element_from(rewrite)
      element.feature = feature_element.feature
      element
      
    rescue Heist::SyntaxError
      feature_element
    end
    
  private
    
    def runtime
      return @runtime if @runtime
      @runtime = Heist::Runtime.new
      @runtime.load(File.dirname(__FILE__) + '/cuke-macros.scm')
      @runtime
    end

    # Scenario
    # ========
    # 
    # [:scenario, 4, "Scenario:", "Standard users",
    #   [:tag, "@outline"],
    #   [:step_invocation, 5, "Given", "I am in group \"<group>\""],
    #   [:step_invocation, 6, "Then", "I should see \"<result>\""]]

    # Scenario Outline
    # ================
    # 
    # [:scenario_outline, "Scenario:", "Standard users",
    #   [:tag, "@outline"],
    #   [:step, 5, "Given", "I am in group \"<group>\""],
    #   [:step, 6, "Then", "I should see \"<result>\""],
    #   [:examples, "Examples:", "",
    #     [:table,
    #       [:row, [:cell, "group"]],
    #       [:row, [:cell, "A"]]]]]

    # Row
    # ===
    # 
    # [:row, 9,
    #   [:cell, "A"],
    #   [:cell, "something"]]
    
    def feature_element_from(sexp)
      return sexp unless Array === sexp
      
      case sexp.first
        when :scenario then
          elements   = sexp[1..-1].map { |e| feature_element_from e }
          background = nil
          comment    = []
          tags       = Tags.new(elements[1], elements.grep(Array).map { |t| t.first })
          line       = elements[0]
          keyword    = elements[1]
          name       = elements[2]
          steps      = elements.grep(Step)
          
          Scenario.new(background, comment, tags, line, keyword, name, steps)
          
        when :scenario_outline then
          elements   = sexp[1..-1].map { |e| feature_element_from e }
          background = nil
          comment    = []
          tags       = Tags.new(elements[0], elements.grep(Array).map { |t| t.first })
          line       = '[generated]'
          keyword    = elements[0]
          name       = elements[1]
          steps      = elements.grep(Step)
          examples   = sexp.last
          
          example_section = [
            [],
            '[generated]',
            examples[1],
            examples[2],
            examples[3][1..-1].map { |row|
              row[2..-1].map { |cell| cell.last }
            }
          ]
          
          ScenarioOutline.new(background, comment, tags, line, keyword, name, steps, [example_section])
          
        when :tag then
          [sexp[1]]
          
        when :step, :step_invocation then
          Step.new(*sexp[1..3])
          
      end
    end
    
    def filter_tags(sexp)
      is_tag = lambda { |e| Array === e and e.first == :tag }
      tags = sexp.select(&is_tag).map { |t| t.last }
      sexp.delete_if &is_tag
      tags
    end
    
    def inject_tags(sexp, tag_names)
      return unless Array === sexp and SCENARIO_TAGS.include? sexp.first
      tags = tag_names.map { |t| [:tag, t] }
      split = sexp[1].is_a?(Numeric) ? 3 : 2
      sexp[0..split] + tags + sexp[(split+1)..-1]
    end
    
  end
end


module Cucumber::Ast
  
  [Scenario, ScenarioOutline].each do |klass|
    klass.class_eval {
      alias :really_accept :accept
      
      def accept(visitor)
        CukeMacros.rewrite(self).really_accept(visitor)
      end
    }
  end
  
end

