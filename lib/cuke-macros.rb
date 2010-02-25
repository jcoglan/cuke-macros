require 'heist'

module CukeMacros
  class << self
    
    include Cucumber::Ast
    
    def load(path)
      runtime.load(path)
    end
    
    def rewrite(feature_element)
      sexp = Heist.parse(feature_element.to_sexp)
      expansion = runtime[sexp.car].call(runtime.top_level, sexp.cdr)
      feature_element_from(expansion.expression.to_ruby)
    end
    
  private
    
    def runtime
      @runtime ||= Heist::Runtime.new
    end
    
    def feature_element_from(sexp)
      return sexp unless Array === sexp
      
      first = sexp.first
      # TODO fix this in Heist
      first = first.expression.to_ruby if Heist::Runtime::Binding === first
      
      case first
        when :scenario then
          elements = sexp[1..-1].map { |e| feature_element_from e }
          background = nil
          comment    = []
          tags       = Tags.new(elements[1], elements.select(&Array.method(:===)).map { |t| t.first })
          line       = elements[0]
          keyword    = elements[1]
          name       = elements[2]
          steps      = elements.select(&Step.method(:===))
          
          Scenario.new(background, comment, tags, line, keyword, name, steps)
          
        when :tag then
          [sexp[1]]
          
        when :step_invocation then
          Step.new(*sexp[1..3])
          
      end
    end
    
  end
end

# Scenario
# ========
# 
# [:scenario, 4, "Scenario:", "Standard users",
#   [:tag, "@outline"],
#   [:step_invocation, 5, "Given", "I am in group \"<group>\""],
#   [:step_invocation, 6, "Then", "I should see \"<result>\""]]

# Row
# ===
# 
# [:row, 9,
#   [:cell, "A"],
#   [:cell, "something"]]

module Cucumber::Ast
  
  class Scenario
    alias :really_accept :accept
    
    def accept(visitor)
      CukeMacros.rewrite(self).really_accept(visitor)
    end
  end
  
end

