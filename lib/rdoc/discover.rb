# Bootstrap file for the Darkfish RDoc generator -- since RDoc doesn't
# know about gems, this file is necessary to get things loaded before RDoc 
# checks to see what generators it knows about.

require 'pathname'
require 'rdoc/rdoc'

generator_dir = Pathname.new( __FILE__ ).dirname + 'generator'

# Add the darkfish generator to the ones RDoc knows about
generator = RDoc::RDoc::Generator.new(
	generator_dir + 'darkfish.rb', 
	:Darkfish,
	'darkfish'
  )

$stderr.puts "Adding 'darkfish' as an RDoc generator type" if $DEBUG
RDoc::RDoc::GENERATORS[ 'darkfish' ] = generator

