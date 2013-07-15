What this is
============

This is a simple CAS written in Ruby.  What I like about this is the ease with which one can create new algebra 
rules to evaluate.  For example, this program does not currently simplify `x*x` into `x^2`.  To add this
functionality, we need only add to the `rules.rb` file the line

`Pattern.new("@1 * @1", "@1^2")`

Not only will adding this rule simplify `x*x` into `x^2`, it will simplify the product of anything with itself
similarly.  For example, it would turn `(2*x+3) * (2*x+3)` into `(2*x+3)^2`.

The current TODO list has two items:
- [] Refactor so that the leaves are not expressions themselves, but are instead stored directly in the parent 
operator's argument array
- [] Flatten the associative operators.  `2 + 3 + 4` should be stored as an expression with operator `+` and
`argument = [2,3,4]`, rather than nesting another `+` operator into it.
