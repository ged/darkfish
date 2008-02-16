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

include Config

$dryrun = false

# Pathname constants
BASEDIR       = Pathname.new( __FILE__ ).dirname.expand_path
LIBDIR        = BASEDIR + 'lib'
MISCDIR       = BASEDIR + 'misc'
PKGDIR        = BASEDIR + 'pkg'

TEXT_FILES    = %w( Rakefile README ).
	collect {|filename| BASEDIR + filename }

LIB_FILES     = Pathname.glob( LIBDIR + '**/*.rb').
	delete_if {|item| item =~ /\.svn/ }
SUPPORT_FILES = Pathname.glob( LIBDIR + '**/*.{css,png,js,rhtml}').
	delete_if {|item| item =~ /\.svn/ }

RELEASE_FILES = TEXT_FILES + LIB_FILES + SUPPORT_FILES

require MISCDIR + 'rake/helpers'

### Package constants
PKG_NAME      = 'darkfish-rdoc'
PKG_VERSION   = find_pattern_in_file( /VERSION = '(\d+\.\d+\.\d+)'/, 
	LIBDIR + 'rdoc/generators/darkfish_generator.rb' ).first
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

RELEASE_NAME  = "REL #{PKG_VERSION}"

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
	rdoc.rdoc_dir = 'rdoc'
	rdoc.title    = "Darkfish Rdoc"

	rdoc.options += [
		'-w', '4',
		'-SHN',
		'-i', 'docs',
		'-f', 'darkfish',
		'-m', 'README',
		'-W', 'http://deveiate.org/projects/Darkfish-Rdoc/browse/trunk/'
	  ]
	
	rdoc.rdoc_files.include 'README'
	rdoc.rdoc_files.include LIB_FILES.collect {|f| f.relative_path_from(BASEDIR).to_s }
end


### Task: gem
gemspec = Gem::Specification.new do |gem|
	pkg_build = get_svn_rev( BASEDIR ) || 0
	
	gem.name    	= PKG_NAME
	gem.version 	= "%s.%s" % [ PKG_VERSION, pkg_build ]

	gem.summary     = ""
	gem.description = <<-EOD
	Darkfish Rdoc Generator -- an alternative Ruby documentation look and feel
	EOD

	gem.authors  	= "Michael Granger"
	gem.homepage 	= "http://deveiate.org/projects/Darkfish-Rdoc/"

	gem.has_rdoc 	= true

	gem.files      	= RELEASE_FILES.
		collect {|f| f.relative_path_from(BASEDIR).to_s }
end
Rake::GemPackageTask.new( gemspec ) do |task|
	task.gem_spec = gemspec
	task.need_tar = false
	task.need_tar_gz = true
	task.need_tar_bz2 = true
	task.need_zip = true
end


### Task: install
desc "Install Darkfish as a conventional library"
task :install do
	log "Installing Darkfish as a conventional library"
	sitelib = Pathname.new( CONFIG['sitelibdir'] )
	Dir.chdir( LIBDIR ) do
		(LIB_FILES + SUPPORT_FILES).each do |libfile|
			relpath = libfile.relative_path_from( LIBDIR )
			target = sitelib + relpath
			FileUtils.mkpath target.dirname,
				:mode => 0755, :verbose => true, :noop => $dryrun unless target.dirname.directory?
			FileUtils.install relpath, target,
				:mode => 0644, :verbose => true, :noop => $dryrun
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


