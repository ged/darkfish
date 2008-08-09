#!/usr/bin/env ruby

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname.parent.parent.parent
	
	libdir = basedir + "lib"
	
	$LOAD_PATH.unshift( libdir ) unless $LOAD_PATH.include?( libdir )
}

begin
	require 'spec/runner'
	require 'rdoc/generator/darkfish'
rescue LoadError
	unless Object.const_defined?( :Gem )
		require 'rubygems'
		retry
	end
	raise
end


describe RDoc::Generator::Darkfish do

	it "can create an instance via the generator factory method" do
		RDoc::Generator::Darkfish.for( 'darkfish' ).
			should be_an_instance_of( RDoc::Generator::Darkfish )
	end
	

	describe "an instance" do
		
		before( :each ) do
			@generator = RDoc::Generator::Darkfish.for( 'darkfish' )
		end
		
		
		it "generates the required subdirectories" do
			@generator.outputdir.should_receive( :mkpath )
			@generator.gen_sub_directories
		end
		
		
		it "copies static files over during #write_style_sheet" do
			FileUtils.should_receive( :cp_r ).
				with( an_instance_of(Pathname), '.', :verbose => $DEBUG ).
				exactly( 3 ).times
			@generator.write_style_sheet
		end
		
	end
end

