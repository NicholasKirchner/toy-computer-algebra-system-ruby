require_relative "rpn.rb"
require_relative "tokens.rb"

class Infix

  def initialize(string)
    @expression = string
  end

  def to_rpn
     return Rpn.new(shunting_yard(@expression))
   end

     #The shunting yard algorithm converts infix to rpn.  It's well documented on wikipedia.

   #Special case: need to convert binary "-" to unary "-" when appropriate.  The only 2 cases are when we have "(-" or we have "-" immediately preceeded by another infix operator.  This conversion is done in infix_to_tokens below.
   #Special case: the (expression) | variable = expression is a ternary operator.
   def shunting_yard(infix)
     output_queue = []
     stack = []
     token_list = infix_to_tokens(infix)
     token_list.each do |token|
       type = Token.type(token)
       if type == "number" || type == "variable" || type == "pattern"
         output_queue << token
       elsif type == "function"
         stack << token
       elsif OPERATIONS[stack[-1]] && token == OPERATIONS[stack[-1]][:separator] #This'll handle the ternary operator(s)
         next
       elsif token == ","
         until stack[-1] == "(" do
           output_queue << stack.pop
         end
       elsif type == "operator"
         while Token.type(stack[-1]) == "operator" && (OPERATIONS[token][:precedence] < OPERATIONS[stack[-1]][:precedence] || (OPERATIONS[token][:precedence] == OPERATIONS[stack[-1]][:precedence] && OPERATIONS[token][:order] == "left"))
           output_queue << stack.pop
         end
         stack << token
       elsif token == "("
         stack << token
       elsif token == ")"
         until stack[-1] == "(" do
           output_queue << stack.pop
         end
         stack.pop
         if Token.type(stack[-1]) == "function"
           output_queue << stack.pop
         end
       end
     end  
     until stack == [] do
       if stack[-1] == "(" || stack[-1] == ")"
         raise "Mismatched parentheses"
       end
       output_queue << stack.pop
     end
     #convert output_queue to string
     return output_queue.join(" ")
   end


   #Read a token from an infix string.
   #allowable characters: 0-9, ., ,, a-z, A-Z, +, -, *, /, ^, |, =
   def get_token(string)
     result = string[0]
     if [",","(",")","="].include?(result) || OPERATIONS[result]

     elsif ("a".."z").include?(result) || ("A".."Z").include?(result)
       #go until find something other than alphanum
       result = string.match(/([a-zA-Z]+)/)[0]
     elsif ("0".."9").include?(result)
       #go until find something other than num and .
       result = string.match(/([\d|\.]+)/)[0]
     elsif result == "@"
       result += string.match(/([\d]+)/)[0]
    else
      raise "Invalid token: #{result[0]}"
    end
    return result
  end

  def infix_to_tokens(infix)
    token_list = []
    infix.strip!
    until infix.length == 0 do
      token = get_token(infix)
      infix.sub!(token,"")
      infix.strip!
      if token == "-" && (Token.type(token_list[-1]) == "operator" || token_list[-1] == "(" || token_list.empty?)
        infix = "u(1)*" + infix
      else
        token_list << token
      end
    end
    return token_list
  end


end
