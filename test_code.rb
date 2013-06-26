require_relative 'operations.rb'
require_relative 'expressions.rb'
require_relative "infix.rb"
require_relative "rules.rb"

a = Expression.new("2 3 +","rpn")
puts a.to_s
b = Expression.new("3 x * 47 sin +", "rpn")
puts b.to_s
c = Expression.new("3 x + 47 sin *", "rpn")
puts c.to_s
d = Expression.new("3 x + y ^", "rpn")
puts d.to_s
a = Expression.new("(2+5)*7")
puts a.to_s
a = Expression.new("sin(x) + cos(y) - (a+x)^47")
puts a.to_s

bigrule = Expression.new("sin(@1)^2 + cos(@1)^2")
fred = Expression.new("sin(2*x+3)^2+cos(2*x+3)^2")
puts fred.pattern_match(bigrule)

smallrule = Expression.new("@1+0")
fred = Expression.new("x+0")
puts fred.pattern_match(smallrule)

doublerule = Expression.new("@1*(@2+@3)")
puts Expression.new("(y*z)*(y+z)-2").pattern_match(doublerule)

a = Expression.new("D(x^x,x)")
puts a.simplify

puts Expression.new("x^x*(x/x + ln(x))").simplify

puts Expression.new("2*3").simplify
