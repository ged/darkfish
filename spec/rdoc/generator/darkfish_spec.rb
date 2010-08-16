#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent
	
	libdir = basedir + "lib"
	
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

require 'spec'
require 'rdoc'
require 'rdoc/generator/darkfish'


describe RDoc::Generator::Darkfish do

	it "can create an instance via the generator factory method" do
		options = RDoc::Options.new
		RDoc::Generator::Darkfish.for( options ).
			should be_an_instance_of( RDoc::Generator::Darkfish )
	end
	

	describe "an instance" do
		
		before( :each ) do
			$dryrun = true
			@options = RDoc::Options.new
			@generator = RDoc::Generator::Darkfish.for( @options )
		end
		
		
		it "generates the required subdirectories" do
			outputdir = mock( "mock outputdir" )
			outputdir.should_receive( :mkpath )
			
			@generator.instance_variable_set( :@outputdir, outputdir )
			@generator.gen_sub_directories
		end
		
		
		it "copies static files over during #write_style_sheet" do
			FileUtils.should_receive( :cp_r ).
				with( an_instance_of(Pathname), '.', :verbose => $DEBUG, :noop => $dryrun ).
				exactly( 3 ).times
			@generator.write_style_sheet
		end
		
		it "adjusts to changes in RDoc 2.2.0 (::build_indices vs. ::build_indicies)" do
			RDoc::Generator::Context.should_receive( :respond_to? ).with( :build_indicies ).
				and_return( false )
			RDoc::Generator::Context.should_receive( :build_indices ).with( :toplevels, @options ).
				and_return([ {}, {} ])

			@generator.generate( :toplevels )
		end
		
	end
end

