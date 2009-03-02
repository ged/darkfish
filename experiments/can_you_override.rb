#!/usr/bin/env ruby

require 'enumerator'

# This is an experiment to see what operator methods from the pickaxe
# (3ed) you can override.  The theory being that if you can override
# it using define_method, you can certainly override it using
# rb_define_method().

OPERATORS = [
	'<<',  '_lshift',
	'>>',  '_rshift',
	'[]=', '_aset',
	'[]',  '_aref',
	'**',  '_pow',
	'~',   '_complement',
	'!',   '_bang',
	'+@',  '_uplus',
	'-@',  '_uminus',
	'+',   '_add',
	'-',   '_sub',
	'*',   '_mult',
	'/',   '_div',
	'%',   '_mod',
	'<=>', '_comp',
	'==',  '_equal',
	'===', '_eqq',
	'>',   '_gt',
	'>=',  '_ge',
	'<',   '_lt',
	'<=',  '_le',
	'&',   '_and',
	'|',   '_or',
	'^',   '_xor',
	'=~',  '_match',
]

class Playground

	OPERATORS.each_slice( 2 ) do |op, name|
		define_method( op ) do 
			puts "Method #{name} works."
		end
	end
	
end

o = Playground.new

o =~ 1
o << 1
o >> 1
o[1]= 1
o[1]
o ** 1
if !o; whee!; end
~o
+o
-o
o + 1
o - 1
o * 1
o / 1
o % 1
o <=> 1
o == 1
o === 1
o > 1
o >= 1
o < 1
o <= 1
o | 1
o & 1
o ^ 1
o =~ 1
