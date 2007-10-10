#!ruby
#
#  Darkfish Rdoc HTML Generator
#  $Id$
#
#  Author: Michael Granger <ged@FaerieMUD.org>
#  
#  == License
#  
#  Copyright (c) 2007, The FaerieMUD Consortium
#  All rights reserved.
#  
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#  
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#  
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.
#  


require 'pp'
require 'pathname'
require 'fileutils'
require 'erb'

require 'rdoc/options'
require 'rdoc/markup/simple_markup'
require 'rdoc/markup/simple_markup/to_html'
require 'rdoc/generators/xml_generator'


### A erb-based RDoc HTML generator
class Generators::DarkfishGenerator < Generators::XMLGenerator
	include ERB::Util

	GENERATOR_DIR = Pathname.new( __FILE__ ).expand_path.dirname


	# Standard generator factory
	def self::for( options )
		new( options )
	end


	### Initialize a few instance variables before we start
	def initialize( *args )
		@template = nil
		@template_dir = GENERATOR_DIR + 'template'
		
		@files      = []
		@classes    = []
		@hyperlinks = {}

		@basedir = Pathname.pwd.expand_path

		super
	end
	
	
	### Create the directories the generated docs will live in if
	### they don't already exist.
	def gen_sub_directories
		@outputdir.mkpath
	end
	

	### Copy over the stylesheet into the appropriate place in the
	### output directory.
	def write_style_sheet
		$stderr.puts "Copying over static files"
		staticfiles = %w[rdoc.css js images]
		staticfiles.each do |path|
			FileUtils.cp_r( @template_dir + path, '.', :verbose => true )
		end
	end
	
	

	### Build the initial indices and output objects
	### based on an array of TopLevel objects containing
	### the extracted information. 
	def generate( toplevels )
		@outputdir = Pathname.new( @options.op_dir ).expand_path( @basedir )

		# Build file documentation
		toplevels.each do |toplevel|
			@files << Generators::HtmlFile.new( toplevel, @options, Generators::FILE_DIR )
		end

		# Build class documentation
		RDoc::TopLevel.all_classes_and_modules.each do |cls|
			self.build_class_list( cls, @files[0], @outputdir.to_s )
		end

		# Now actually write the output
		generate_xhtml( @options, @files, @classes )

	rescue StandardError => err
		$stderr.puts "%s: %s\n  %s" % [ err.class.name, err.message, err.backtrace.join("\n  ") ]
	end


	### Build pages for each class by traversing the class hierarchy. Append each new 
	### generated class page to the array of class pages. 
	def build_class_list( cls, html_file, class_dir )
		@classes << Generators::HtmlClass.new( cls, html_file, class_dir, @options )
		cls.each_classmodule do |mod|
			build_class_list( mod, html_file, class_dir )
		end
	end


	### No-opped
	def load_html_template # :nodoc:
	end


	### Generate output
	def generate_xhtml( options, files, classes )
		files = gen_into( @files )
		classes = gen_into( @classes )

		classes_by_classname = classes.inject({}) {|hash, classinfo|
			hash[ classinfo['full_name'] ] = classinfo
			hash[ classinfo['full_name'] ][:outfile] =
				classinfo['full_name'].gsub( /::/, '/' ) + '.html'
			hash
		}

		files_by_path = files.inject({}) {|hash, fileinfo|
			hash[ fileinfo['full_path'] ] = fileinfo
			hash[ fileinfo['full_path'] ][:outfile] = 
				fileinfo['full_path'] + '.html'
			hash
		}
		
		self.write_style_sheet
		self.generate_index( options, files_by_path, classes_by_classname )
		self.generate_class_files( options, files_by_path, classes_by_classname )
		self.generate_file_files( options, files_by_path, classes_by_classname )
	end



	#########
	protected
	#########

	### Return a list of the documented modules sorted by salience first, then by name.
	def get_sorted_module_list( classes )
		nscounts = classes.keys.inject({}) do |counthash, name|
			toplevel = name.gsub( /::.*/, '' )
			counthash[toplevel] ||= 0
			counthash[toplevel] += 1
			
			counthash
		end

		# Sort based on how often the toplevel namespace occurs, and then on the name 
		# of the module -- this works for projects that put their stuff into a 
		# namespace, of course, but doesn't hurt if they don't.
		return classes.keys.sort_by do |name| 
			toplevel = name.gsub( /::.*/, '' )
			[
				nscounts[ toplevel ] * -1,
				name
			]
		end
	end
	
	
	### Generate an index page which lists all the classes which
	### are documented.
	def generate_index( options, files, classes )
		$stderr.puts "Rendering the index page..."

		templatefile = @template_dir + 'index.rhtml'
		template_src = templatefile.read
		template = ERB.new( template_src, nil, '<>' )
		template.filename = templatefile.to_s
		context = binding()

		modsort = self.get_sorted_module_list( classes )
		output = nil
		begin
			output = template.result( context )
		rescue NoMethodError => err
			raise "Error while evaluating %s: %s (at %p)" % [
				templatefile,
				err.message,
				eval( "_erbout[-50,50]", context )
			]
		end

		outfile = @basedir + @options.op_dir + 'index.html'
		unless $dryrun
			$stderr.puts "Outputting to %s" % [outfile.expand_path]
			outfile.open( 'w', 0644 ) do |fh|
				fh.print( output )
			end
		else
			$stderr.puts "Would have output to %s" % [outfile.expand_path]
		end
	end



	### Generate a documentation file for each class present in the
	### given hash of +classes+.
	def generate_class_files( options, files, classes )
		$stderr.puts "Generating class documentation"
		templatefile = @template_dir + 'classpage.rhtml'
		outputdir = @outputdir

		modsort = self.get_sorted_module_list( classes )

		classes.sort_by {|k,v| k }.each do |classname, classinfo|
			$stderr.puts "  working on %s (%s)" % [ classname, classinfo[:outfile] ]
			outfile    = outputdir + classinfo[:outfile]
			rel_prefix = outputdir.relative_path_from( outfile.dirname )
			svninfo    = self.get_svninfo( classinfo )

			self.render_template( templatefile, binding(), outfile )
		end
	end


	### Generate a documentation file for each file present in the
	### given hash of +files+.
	def generate_file_files( options, files, classes )
		$stderr.puts "Generating file documentation"
		templatefile = @template_dir + 'filepage.rhtml'

		files.sort_by {|k,v| k }.each do |path, fileinfo|
			$stderr.puts "  working on %s (%s)" % [ path, fileinfo[:outfile] ]
			outfile     = @outputdir + fileinfo[:outfile]
			rel_prefix  = @outputdir.relative_path_from( outfile.dirname )
			context     = binding()

			self.render_template( templatefile, binding(), outfile )
		end
	end


	### Return a string describing the amount of time in the given number of
	### seconds in terms a human can understand easily.
	def time_delta_string( seconds )
		return 'less than a minute' if seconds < 1.minute 
		return (seconds / 1.minute).to_s + ' minute' + (seconds/60 == 1 ? '' : 's') if seconds < 50.minutes
		return 'about one hour' if seconds < 90.minutes
		return (seconds / 1.hour).to_s + ' hours' if seconds < 18.hours
		return 'one day' if seconds < 1.day
		return 'about one day' if seconds < 2.days
		return (seconds / 1.day).to_s + ' days' if seconds < 1.week
		return 'about one week' if seconds < 2.week
		return (seconds / 1.week).to_s + ' weeks' if seconds < 3.months
		return (seconds / 1.month).to_s + ' months' if seconds < 1.year
		return (seconds / 1.year).to_s + ' years'
	end


	# %q$Id$"
	SVNID_PATTERN = /
		\$Id:\s 
			(\S+)\s					# filename
			(\d+)\s					# rev
			(\d{4}-\d{2}-\d{2})\s	# Date (YYYY-MM-DD)
			(\d{2}:\d{2}:\d{2}Z)\s	# Time (HH:MM:SSZ)
			(\w+)\s				 	# committer
		\$$
	/x

	### Try to extract Subversion information out of the first constant whose value looks like
	### a subversion Id tag. If no matching constant is found, and empty hash is returned.
	def get_svninfo( classinfo )
		return {} unless classinfo['sections']
		constants = classinfo['sections'].first['constants'] or return {}
	
		constants.find {|c| c['value'] =~ SVNID_PATTERN } or return {}

		filename, rev, date, time, committer = $~.captures
		commitdate = Time.parse( date + ' ' + time )
		
		return {
			:filename    => filename,
			:rev         => Integer( rev ),
			:commitdate  => commitdate,
			:commitdelta => time_delta_string( Time.now.to_i - commitdate.to_i ),
			:committer   => committer,
		}
	end


	### Load and render the erb template in the given +templatefile+ within the specified 
	### +context+ (a Binding object) and write it out to +outfile+. Both +templatefile+ and 
	### +outfile+ should be Pathname-like objects.
	def render_template( templatefile, context, outfile )
		template_src = templatefile.read
		template = ERB.new( template_src, nil, '<>' )
		template.filename = templatefile.to_s

		output = begin
			template.result( context )
		rescue NoMethodError => err
			raise "Error while evaluating %s: %s (at %p)" % [
				templatefile.to_s,
				err.message,
				eval( "_erbout[-50,50]", context )
			]
		end

		unless $dryrun
			outfile.dirname.mkpath
			outfile.open( 'w', 0644 ) do |ofh|
				ofh.print( output )
			end
		else
			$stderr.puts "  would have written %d bytes to %s" %
			[ output.length, outfile ]
		end
	end

end # Generators::DarkfishGenerator

# Make an alias for Rdoc's silly generator lookup (which is probably my fault)
Generators::DARKFISHGenerator = Generators::DarkfishGenerator

