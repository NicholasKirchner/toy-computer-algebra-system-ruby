#Each expression contains an operator and an array of its arguments.  Terminal 
#nodes in the tree have the operator being a number, with arguments being an 
#empty array.  Maybe refactor so that the nodes themselves are not Expressions?


class Expression

  attr_accessor :argument, :operator

  #I have 4 ways to store a mathematical expression:
  # 1: infix (as written by a human)
  # 2: rpn
  # 3: tree of arrays
  # 4: tree of expressions (canonical for this program)
  # I can do the conversions most easily 1 => 2 => 3 => 4 => 1

  def initialize(expression, type = "infix", operator = nil, argument = nil)
    if type == "direct"
      @operator = operator
      @argument = argument
      return self
    end

    if type == "infix"
      expression = Infix.new(expression).to_rpn.to_array_tree
    elsif type == "rpn"
      expression = Rpn.new(expression).to_array_tree
    end

    #Now make tree of expressions
    if OPERATIONS[expression[0]]
      @operator = Token.new(expression[0])
      @argument = expression[1].map { |x| Expression.new(x,"array") }
    else
      @operator = Token.new(expression)
      @argument = nil
    end

  end

  def type
    argument ? "Expression" : Token.type(operator)
  end

  def op_char
    @operator ? @operator.token : nil
  end

  def to_s #converts the Expression to infix

    if is_leaf? #if it's a number or variable, return it as a string
      return @operator.to_s

    #If it's standard functional form (i.e. f(x) ), put the operator followed by the arguments in parentheses separated by commas.
    elsif OPERATIONS[op_char][:inline] == nil
      if op_char == "u"
        return "(-" + @argument[0].to_s + ")"
      else
        arg_strings = @argument.map { |x| x.to_s }
        return op_char + "(" + arg_strings.join(',') + ")"
      end
    #This is going to get ugly...  infix operators!  I freely say that there's no nice way to do this.
    #Basically: determine using precedence, associativity and order rules whether to put parentheses around arguments.  Example: "3 x + 2 *" should render as "(3+x)*2", where the precedence has determined that we need parens around the addition.
    #Corner cases: 4 3 2 - - needs to be 4-(3-2) and not 4-3-2=(4-3)-2, since subtraction proceeds left to right.
    # 4 3 2 + + can be written as 4+3+2 since addition is associative
    # 4 3 ^ 2 ^ needs to be (4^3)^2, and not 4^3^2=4^(3^2) since exponentiation proceeds right to left
    #And a very special case: we probably should write (sin(x))^2 and not sin(x)^2.  Perhaps more elegently done by giving function evaluation precedence between multiplication and exponentiation?
    #Finally, there's the matter of the ternary operator...
    else
      beginning = @argument[0].to_s
      ending = @argument[1].to_s
      if !(@argument[0].is_leaf?)
        if OPERATIONS[@argument[0].op_char][:inline] != nil
          upper_precedence = OPERATIONS[op_char][:precedence]
          lower_precedence = OPERATIONS[@argument[0].op_char][:precedence]
          if upper_precedence > lower_precedence || (upper_precedence == lower_precedence && OPERATIONS[op_char][:order] == "right" and OPERATIONS[op_char][:associativity] == false)
            beginning = "(#{beginning})"
          end
        end
        if op_char == "^" && OPERATIONS[@argument[0].op_char][:inline] == nil
          beginning = "(#{beginning})"
        end
      end
      
      if !(@argument[1].is_leaf?)
        if OPERATIONS[@argument[1].op_char][:inline] != nil
          upper_precedence = OPERATIONS[op_char][:precedence]
          lower_precedence = OPERATIONS[@argument[1].op_char][:precedence]
          if upper_precedence > lower_precedence || (upper_precedence == lower_precedence && OPERATIONS[op_char][:order] == "left" && OPERATIONS[op_char][:associativity] == false)
            ending = "(#{ending})"
          end
        end
      end
      return beginning + op_char + ending
    end
  end

  #This function will compare self against another expression with pattern 
  #tokens.  Recursively calls itself down the tree, adding to the "assigned" 
  #hash.  Result is of the form { "@1" => (expr1), "@2" => (expr2), ...} if the
  #pattern matches, and false if the pattern does not match.

  def pattern_match(pattern, assigned = {})
    return false if pattern.operator != @operator

    if is_leaf?
      pattern_key = Expression.pattern_index(pattern)
      if !pattern_key
        return @operator == pattern.operator ? assigned : false
      else
        if assigned[pattern_key]
          return assigned[pattern_key] == @operator ? assigned : false
        else
          assigned[pattern_key] = self
          return assigned
        end
      end
    else
      (0...@argument.length).each do |i|
        pattern_key = Expression.pattern_index(pattern.argument[i])
        if !pattern_key
          assigned = @argument[i].pattern_match(pattern.argument[i], assigned)
          return false if !assigned
        else
          if assigned[pattern_key]
            if assigned[pattern_key] != @argument[i]
              return false
            end
          else
            assigned[pattern_key] = @argument[i]
          end
        end
      end
      return assigned
    end
  end

  #detects whether the given expression is a pattern token (i.e. starts with 
  #"@").  If so, returns the token.  Otherwise, nil.
  def self.pattern_index(expr)
    (expr && expr.operator[0] == "@") ? expr.operator.token : nil
  end

  def ==(other)
    return other.class == Expression && self.operator == other.operator && self.argument == other.argument
  end

  #Compares self against all patterns in the $rules hash and simplifies
  #accordingly.

  def simplify
    return self unless @argument
    if argument.all? { |arg| arg.is_leaf? && Token.type(arg.operator) == "number" }
      p @argument
      args = argument.map { |arg| arg.operator.to_num }
      @operator = OPERATIONS[@operator.token][:numeric].call(*args)
      @argument = nil
    end
    new = self
    begin
      
      old = new
      new.argument = new.argument.map { |arg| arg.simplify } unless new.is_leaf?
      $rules.each do |rule|
        new = rule.apply_to(new)
      end
      
    end while old != new
    return new
  end

  #Replaces all *terminal* nodes of self which are equal to old_leaf.
  #new_leaf, which can be an expression or a token, is inserted in old_leaf's
  #place.

  def replace_leaves(old_leaf, new_leaf)
    if is_leaf?
      if new_leaf.class == Expression
        new_op = (@operator == old_leaf) ? new_leaf.operator : @operator
        new_arg = (@operator == old_leaf) ? new_leaf.argument : nil
        return Expression.new("", "direct", new_op, new_arg)
      else
        return Expression.new("", "direct", @operator == old_leaf ? new_leaf : @operator, nil)
      end
    else
      return Expression.new("", "direct", @operator, @argument.map { |arg| arg.replace_leaves(old_leaf, new_leaf) })
    end
  end

  def is_leaf?
    return !argument
  end

  #TODO

  def has_leaf?(token)
    
  end

end
