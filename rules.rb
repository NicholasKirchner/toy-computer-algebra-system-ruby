class PatternRule
  
  def initialize( before, after, restrictions = {} )
    @before = (before.class == Expression ? before : Expression.new(before))
    @after = (after.class == Expression ? after : Expression.new(after))
    @restrictions = restrictions
  end

  def apply_to(expression)
    substitutions = expression.pattern_match(@before) || {}
    return expression if substitutions.empty?

    @restrictions.each do |pattern, restriction|
      if restriction[:args]
        args = restriction[:args].map { |arg| substitutions[arg] || arg }
      else
        args = []
      end
      if substitutions[pattern].send(restriction[:function].to_sym,
                                    *args) != restriction[:result]
        return expression
      end
    end

    result = @after
    substitutions.each do |key, expression|
      pattern = Token.new(key)
      result = result.replace_leaves(pattern,expression)
    end
    result
  end

  #def to_s
  #  "before: #{@before}, after #{@after}"
  #end
  
end

$rules = [ PatternRule.new(Expression.new("@1 + 0"), Expression.new("@1")),
           PatternRule.new(Expression.new("0 + @1"), Expression.new("@1")),
           PatternRule.new(Expression.new("@1 - 0"), Expression.new("@1")),
           PatternRule.new(Expression.new("0 - @1"), Expression.new("-(@1)")),
           PatternRule.new(Expression.new("@1 * 0"), Expression.new("0")),
           PatternRule.new(Expression.new("0 * @1"), Expression.new("0")),
           PatternRule.new(Expression.new("@1 - @1"), Expression.new("0")),
           PatternRule.new(Expression.new("1 * @1"), Expression.new("@1")),
           PatternRule.new(Expression.new("@1 * 1"), Expression.new("@1")),
           PatternRule.new(Expression.new("0 / @1"), Expression.new("0")),
           PatternRule.new(Expression.new("@1 / @1"), Expression.new("1")),
           PatternRule.new(Expression.new("@1 ^ 0"), Expression.new("1")),
           PatternRule.new(Expression.new("@1 ^ 1"), Expression.new("@1")),
           PatternRule.new(Expression.new("1 ^ @1"), Expression.new("1")),
           #this one isn't true when @1 is negative.
           #PatternRule.new(Expression.new("0 ^ @1"), Expression.new("0")),
           PatternRule.new(Expression.new("@1 / 1"), Expression.new("@1")),
           PatternRule.new("D(@1,@1)", "1"),
           PatternRule.new("D(-@1, @2)", "-(D(@1,@2))"),
           PatternRule.new("D(@1 + @2, @3)", "D(@1,@3) + D(@2,@3)"),
           PatternRule.new("D(@1 - @2, @3)", "D(@1,@3) - D(@2,@3)"),
           PatternRule.new("D(@1 * @2, @3)", "@1 * D(@2,@3) + @2 * D(@1,@3)"),
           PatternRule.new("D(@1 / @2, @3)", "D(@1 * @2^(-1), @3)"),
           PatternRule.new("D(@1 ^ @2, @3)", 
                           "@1^@2 * (D(@1,@3) * @2 / @1 + D(@2,@3) * ln(@1))"),

           PatternRule.new("D(@1, @2)", "0",
                           { "@1" => { :function => "type",
                                       :result => "number" } } ),
           PatternRule.new("D(@1, @2)", "0",
                           { "@2" => { :function => "type", 
                                       :result => "variable" },
                             "@1" => { :function => "has_leaf?",
                                       :args => ["@2"], 
                                       :result => false } } )
         ]
