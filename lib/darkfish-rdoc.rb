# Bootstrap file for the Darkfish RDoc generator -- since RDoc doesn't
# know about gems, this file is necessary to get things loaded before RDoc 
# checks to see what generators it knows about.

require 'pathname'
require 'rdoc/rdoc'

begin
	generator_dir = Pathname.new( __FILE__ ).dirname + 'rdoc/generators'

	# Add the darkfish generator to the ones RDoc knows about
	generator = RDoc::RDoc::Generator.new(
		generator_dir + 'darkfish_generator.rb', 
		:DarkfishGenerator,
		'darkfish'
	  )
	RDoc::RDoc::GENERATORS[ 'darkfish' ] = generator
end




