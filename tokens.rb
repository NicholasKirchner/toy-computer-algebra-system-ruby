class Token

  def self.type(string)
    if string == nil
      return nil
    elsif string == "i"
      return "number"
    elsif ("a".."z").include?(string[0]) || ("A".."Z").include?(string[0])
      return OPERATIONS[string] ? "function" : "variable"
    elsif ("0".."9").include?(string[0])
      return "number"
    elsif OPERATIONS[string[0]]
      return "operator"
    elsif string[0] == "@"
      return "pattern"
    elsif [",","(",")","="].include?(string)
      return string
    end
    raise "Invalid token: #{string}"
  end

  attr_reader :type, :token

  def initialize(string)
    @token = string
    @type = Token.type(string)
    to_num
  end

  #intelligently convert a numerical token to a number.
  def to_num
    if token == "i"
      return token.to_c
    elsif token.include? "."
      return token.to_f
    elsif (token =~ /[a-zA-Z]/) == 0
      return token
    else
      return token.to_i
    end
  end

  def [](index)
    return @token[index]
  end

  def to_s
    return @token.to_s
  end

  def ==(other)
    return other.class == Token && self.token == other.token
  end

end
