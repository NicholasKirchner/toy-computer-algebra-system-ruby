class Rpn

  def initialize(string)
    @expression = string
  end

  def to_array_tree
    #Convert RPN to tree of arrays
    stack = []
    @expression.split(' ').each do |token|
      if OPERATIONS[token]
        value = [ token, stack.pop( OPERATIONS[token][:arguments] ) ]
      else
        value = token
      end
      stack << value
    end
    return stack[0]
  end

  def to_s
    @expression
  end

end
