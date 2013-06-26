require_relative 'operations.rb'
require_relative 'expressions.rb'
require_relative "infix.rb"
require_relative "rules.rb"


a = Expression.new("D(3*x^2,x)")
puts a.simplify
