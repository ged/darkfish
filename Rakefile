#!rake
#
# Darkfish Rdoc Rakefile
#
# Copyright (c) 2008, The FaerieMUD Consortium
#
# Authors:
#  * Michael Granger <ged@FaerieMUD.org>
#

BEGIN {
	require 'pathname'
	basedir = Pathname.new( __FILE__ ).dirname
	libdir = basedir + 'lib'
	docsdir = basedir + 'docs'

	$LOAD_PATH.unshift( libdir.to_s ) unless $LOAD_PATH.include?( libdir.to_s )
	$LOAD_PATH.unshift( docsdir.to_s ) unless $LOAD_PATH.include?( docsdir.to_s )
}


require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'pathname'
require 'rbconfig'
require 'rdoc/generator/darkfish_generator'


include Config

$dryrun = false

# Pathname constants
BASEDIR       = Pathname.new( __FILE__ ).dirname.relative_path_from( Pathname.pwd )
LIBDIR        = BASEDIR + 'lib'
MISCDIR       = BASEDIR + 'misc'
PKGDIR        = BASEDIR + 'pkg'

TEXT_FILES    = Pathname.glob( BASEDIR + '{Rakefile,README}' )
LIB_FILES     = Pathname.glob( LIBDIR + '**/*.rb' )
SUPPORT_FILES = Pathname.glob( LIBDIR + '**/*.{css,png,js,rhtml}' )

RELEASE_FILES = TEXT_FILES + LIB_FILES + SUPPORT_FILES

require MISCDIR + 'rake/helpers'

### Package constants
PKG_NAME      = 'darkfish-rdoc'
PKG_VERSION   = find_pattern_in_file( /VERSION = '(\d+\.\d+\.\d+)'/, 
	LIBDIR + 'rdoc/generator/darkfish_generator.rb' ).first
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

RELEASE_NAME  = "REL #{PKG_VERSION}"


RDOC_OPTIONS = [
	'-w', '4',
	'-SHN',
	'-m', 'README',
	'-W', 'http://deveiate.org/projects/Darkfish-Rdoc/browser/trunk/'
  ]

# Load task plugins
RAKE_TASKDIR = MISCDIR + 'rake'
Pathname.glob( RAKE_TASKDIR + '*.rb' ).each do |tasklib|
	next if tasklib =~ %r{/helpers.rb$}
	require tasklib
end

if Rake.application.options.trace
	$trace = true
	log "$trace is enabled"
end

if Rake.application.options.dryrun
	$dryrun = true
	log "$dryrun is enabled"
	Rake.application.options.dryrun = false
end

### Default task
task :default  => [:clean, :package]


### Task: clean
desc "Clean pkg, coverage, and rdoc; remove .bak files"
task :clean => [ :clobber_package ] do
	files = FileList['**/*.bak']
	files.clear_exclude
	File.rm( files ) unless files.empty?
end



### Task: rdoc
Rake::RDocTask.new do |rdoc|
	rdoc.title    = "%s - %s" % [ PKG_NAME, PKG_VERSION ]

	rdoc.options += RDOC_OPTIONS
	rdoc.options += [ '-f', 'darkfish' ]
	
	rdoc.rdoc_files.include 'README'
	rdoc.rdoc_files.include LIB_FILES.collect {|path| path.to_s }
end


### Task: gem
GEMSPEC = Gem::Specification.new do |gem|
	pkg_build = get_svn_rev( BASEDIR ) || 0
	
	gem.name    	= PKG_NAME
	gem.version 	= PKG_VERSION

	gem.summary     = "an alternative Ruby documentation look and feel"
	gem.description = <<-EOD
	This an alternative HTML generator library for RDoc that generates a single-frame,
	javascript-enhanced view of your Ruby classes, with an emphasis on clean lines
	and customizability via CSS. 
	EOD

	gem.authors  	= "Michael Granger"
	gem.email  	    = "ged@FaerieMUD.org"
	gem.homepage 	= "http://deveiate.org/projects/Darkfish-Rdoc/"

	gem.has_rdoc 	= true
	gem.extra_rdoc_files << 'README'
	gem.rdoc_options += RDOC_OPTIONS
	
	gem.rubyforge_project = 'deveiate'

	gem.files      	= RELEASE_FILES.
		collect {|f| f.relative_path_from(BASEDIR).to_s }
end

GEMFILE = PKGDIR + "#{PKG_NAME}-#{PKG_VERSION}.gem"

directory PKGDIR.to_s
file GEMFILE.to_s => [PKGDIR.to_s] + GEMSPEC.files do
	when_writing( "Creating GEM" ) do
		gem_file = Gem::Builder.new( GEMSPEC ).build
		verbose(true) do
			mv gem_file, GEMFILE
		end
	end
end

task :gem => GEMFILE.to_s


### Task: package
Rake::PackageTask.new( PKG_NAME, PKG_VERSION ) do |task|
	task.package_files = RELEASE_FILES
	task.need_tar = false
	task.need_tar_gz = true
	task.need_tar_bz2 = true
	task.need_zip = true
end
task :package => [ :gem ]


### Task: install
desc "Install Darkfish as a conventional library"
task :install do
	sitelib = Pathname.new( CONFIG['sitelibdir'] )
	log "Installing Darkfish in #{sitelib}"
	Dir.chdir( LIBDIR ) do
		(LIB_FILES + SUPPORT_FILES).each do |libfile|
			relpath = libfile.relative_path_from( LIBDIR )
			target = sitelib + relpath
			when_writing( "Copying..." ) do
				FileUtils.mkpath target.dirname,
					:mode => 0755, :verbose => true, :noop => $dryrun unless target.dirname.directory?
				FileUtils.install relpath, target,
					:mode => 0644, :verbose => true, :noop => $dryrun
			end
		end
	end
end

desc "Uninstall Darkfish installed as a conventional library"
task :uninstall do
	sitelib = Pathname.new( CONFIG['sitelibdir'] )
	log "Uninstalling Darkfish from #{sitelib}"
	generator_dir = sitelib + 'rdoc/generators'
	generator     = generator_dir + 'darkfish_generator.rb'
	generator_lib = generator_dir + 'template/darkfish'

	when_writing( "Uninstalling" ) do
		verbose( true ) do
			FileUtils.rm_f( generator )
			FileUtils.rm_rf( generator_lib )
		end
	end
end


### Task: install
task :install_gem => [:package] do
	$stderr.puts 
	installer = Gem::Installer.new( %{pkg/#{PKG_FILE_NAME}.gem} )
	installer.install
end

### Task: uninstall
task :uninstall_gem => [:clean] do
	uninstaller = Gem::Uninstaller.new( PKG_FILE_NAME )
	uninstaller.uninstall
end


