#!/usr/bin/env ruby
# echo hi from Inmake::Config!
require 'inmake/version'
module Inmake

  ##
  # Stores inmake configuration options.
  # 
  class Config
    attr_reader :dirMode, :searchMode, :searchArgument, :stripMatched, 
                :variables, :files, :variablesDisabled, :ignoreNonmatches
    attr_writer :variables, :files
    def initialize opts
      # How we treat directories that have been passed to the file list.
      # Possible values are :acceptDirs, :ignoreDirs
      # :acceptDirs => directories are accepted and recursed into
      # :ignoreDirs => directories are ignored
      @dirMode = opts[:dirMode]
      # A list of all the files that inmake will act on.
      # This may include directories or relative paths.
      @files = opts[:files]
      # How inmake looks for the build command inside the file. Possible values
      # are :prefix, :suffix, :regex, :secondLine
      # :prefix => search each line start for a prefix 
      # :suffix => search each line ending for a suffix
      # :regex  => search each line via an actual regex
      # :secondLine => use the second line (or third if the second looks like an
      #                encoding line like Python)
      @searchMode = opts[:searchMode]
      # An additional argument to specify the thing that the search mode uses
      # to look for the build command. AKA, the actual prefix string or suffix
      # string or the regex object.
      @searchArgument = opts[:searchArgument]
      # Do we strip all found parts of the regex from the build command?
      @stripMatched = opts[:stripMatched]
      # Hash of variables that can be replaced in the build command
      @variables = opts[:variables]
      # Are variables disabled overall? Even the builtins that is...
      @variablesDisabled = opts[:variablesDisabled]
      # Do we stop when a file didn't have a command inside?
      @ignoreNonmatches = opts[:ignoreNonmatches]
    end

    def self.fromArguments
      require 'optparse'
      
      opts = {}
      opts[:files] = []
      opts[:variables] = {}

      # Parse special arguments
      OptionParser.new do |parser|
        parser.banner = INMAKE_BANNER

        parser.on('-f', '--file FILENAME', 'Specify a target file.') do |filename|
          opts[:files] << filename
        end

        parser.on('-p', '--prefix PREFIX', 'Find the build command by a prefix.') do |prefix|
          unless opts[:searchMode]
            opts[:searchMode] = :prefix
            opts[:searchArgument] = prefix
          else
            raise MultipleModeException, "Multiple search mode definitions!"
          end
        end

        parser.on('-s', '--suffix SUFFIX', 'Find the build command by a suffix.') do |suffix|
          unless opts[:searchMode]
            opts[:searchMode] = :suffix
            opts[:searchArgument] = suffix
          else
            raise MultipleModeException, "Multiple search mode definitions!"
          end
        end

        
        okDirModes = [:acceptDirs, :ignoreDirs]
        parser.on('-d', '--dir-mode MODE', "Define behavior when dealing with a directory. (default: acceptDirs) Accepted values are: #{okDirModes.join ', '}") do |dm|
          dm = dm.to_sym
          raise InvalidDirMode, "Not a valid directory mode: #{dm}" unless okDirModes.include? dm 
          opts[:dirMode] = dm
        end

        parser.on('-x', '--regex REGEX', 'Specify a regular expression to match the build command.') do |rx|
          unless opts[:searchMode]
            re = Regexp.compile rx
            opts[:searchMode] = :regex
            opts[:searchArgument] = re
          else
            raise MultipleModeException, "Multiple search mode definitions!"
          end
        end

        parser.on('--[no-]strip-matched', 'Strip all found matches on a regex search (default: false)') do |f|
          opts[:stripMatched] = f
        end

        parser.on('--[no-]ignore-nonmatched', 'Silently continue if a file does not seem to have a build command (default: true)') do |f|
          opts[:ignoreNonmatches] = f
        end

        parser.on('--no-vars', 'Disable all replacement variables, even the builtin ones (default: false)') do |v|
          opts[:variablesDisabled] = v
        end

        parser.on('-a', '--add-var KEY=VALUE', 'Add a replacement from {{KEY}} (always allcaps!) to VALUE, much like a C preprocessor definition') do |var|
          key, value = var.split '='
          raise InvalidVarDefinition, "Invalid variable definition syntax: `#{var}`" unless key and value

          opts[:variables][key.upcase] = value
        end

      end.parse!

      # any arguments that weren't flags are just treated as file names
      unless ARGV.empty?
        opts[:files].concat ARGV
      end

      # The default search mode is to find the build command on the second line of 
      # the source code.
      opts[:searchMode] ||= :secondLine 

      # The default file mode means that if a directory is encountered, we recurse
      # on all its files.
      opts[:dirMode] ||= :acceptDirs 

      # Variables are enabled by default.
      opts[:variablesDisabled] ||= false

      # By default, we do not strip the matched string.
      opts[:stripMatched] ||= false

      opts[:ignoreNonmatched] = true unless defined? opts[:ignoreNonmatched]
      
      # Can't run without ANY files...
      raise NoFilesGiven, "No input files specified! Use #{$0} --help for how to add input files." if opts[:files].empty?

      # return a new Config object
      return Config.new opts
    end


    def self.resolveFiles cfg
      newFiles = []
      cfg.files.each do |f|
        if File.exist? f 
          if File.file? f
            newFiles << f
          elsif File.directory? f and cfg.dirMode == :acceptDirs
            newFiles.concat Dir[File.join(f, '**/*.*')].select {|x| File.file? x }
          end
        end
      end

      cfg.files = newFiles.map { |x| File.expand_path x }
      cfg
    end
  end

  ##
  # Multiple search modes were defined when reading definitions from the
  # command line (eg regex and prefix at the same time)
  class MultipleModeException < StandardError; end
  ##
  # A variable was defined with wrong syntax when on the command line!
  # (not something=something)
  class InvalidVarDefinition < StandardError; end
  ##
  # No files added
  class NoFilesGiven < StandardError; end
  ## 
  # The directory handling mode was invalid!
  class InvalidDirMode < StandardError; end
end

INMAKE_BANNER = <<-EOF
inmake v#{Inmake::VERSION} - the inline build command runner
Runs commands directly embedded inside your source code. 
Usage: #{$0} [options...] [files]
Options:

EOF
