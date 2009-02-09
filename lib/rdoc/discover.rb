# Bootstrap file for the Darkfish RDoc generator. Tell RubyGems about Darkfish
# via autodiscovery.

gem 'darkfish-rdoc'

if Gem.respond_to?( :promote_load_path )
	Gem.promote_load_path( 'darkfish-rdoc', 'rdoc' )
else
	# move darkfish-rdoc before rdoc in the load path so ours gets picked up first
	# NOTE: This was added as Gem::promote_load_path in RubyGems 1.4
	rdoc = Gem.loaded_specs['rdoc']
	darkfish = Gem.loaded_specs['darkfish-rdoc']

	last_darkfish_path = File.join( darkfish.full_gem_path,
	                                darkfish.require_paths.last )

	rdoc_paths = rdoc.require_paths.map do |path|
		File.join( rdoc.full_gem_path, path )
	end

	rdoc_paths.each do |path|
		$LOAD_PATH.delete( path )
	end

	darkfish_path_index = $LOAD_PATH.index( last_darkfish_path ) + 1

	$LOAD_PATH.insert( darkfish_path_index, *rdoc_paths )
end

require 'rdoc/generator/darkfish'

