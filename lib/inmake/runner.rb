#!/usr/bin/env ruby
# echo Hi from Inmake::Runner!
module Inmake
  ##  
  # = Inmake Command Runner
  # 
  # Finds and runs the commands inside all of the files.
  # The same search mode is used for every file.
  class Runner

    # Set up a runner with a configuration object defined earlier.
    def initialize cfg
      @config = cfg
    end

    # Run inmake on each of the files defined in the configuration
    def run
      @config.files.each do |x| 
        begin 
          dispatch x 
        rescue CommandNotFound => e
          raise unless @config.ignoreNonmatches
        end
      end
    end
    
    # Find and run a command in a given file, depending on the search mode
    def dispatch file
      File.open(file) do |fd|
        fd.flock File::LOCK_EX
        if @config.searchMode == :prefix
          runPrefix fd
        elsif @config.searchMode == :suffix
          runSuffix fd
        elsif @config.searchMode == :regex
          runRegex fd
        elsif @config.searchMode == :secondLine
          runSecondLine fd
        end
      end
    end

    # Apply variables and then run the found build command
    def applyCommand cmd, fd
      
      unless @config.variablesDisabled
        @config.variables.each do |k, v|
          cmd.gsub! '{{'+k.to_s+'}}', v
        end

        cmd.gsub! '{{f}}', fd.path
        cmd.gsub! '{{bn}}', File.basename(fd.path)
        cmd.gsub! '{{bn1}}', File.basename(fd.path, '.*')
        cmd.gsub! '{{ext}}', File.extname(fd.path)
        cmd.gsub! '{{dn}}', File.dirname(fd.path)
        st = fd.stat
        cmd.gsub! '{{mode}}', st.mode.to_s
        cmd.gsub! '{{mtime}}', st.mtime.to_i.to_s
        cmd.gsub! '{{ctime}}', st.ctime.to_i.to_s
        cmd.gsub! '{{size}}', st.size.to_s
      end
      fd.flock File::LOCK_UN
      system cmd
      puts cmd
    end

    # Find a given prefix in a file and apply the build command on match
    def runPrefix fd
      rx = /^\s*#{Regexp.escape @config.searchArgument}\s*/
      command = fd.each_line.detect do |line|
        rx.match line
      end
      raise CommandNotFound, "Did not find a prefixed command in file `#{fd.path}`" unless command
      command.gsub!(rx, '')

      applyCommand command, fd
    end

    # Find a given suffix in a file and apply the build command when matched
    # Raises CommandNotFound if no command was found in a file
    def runSuffix fd
      rx = /#{Regexp.escape @config.searchArgument}\s*$/
      command = fd.each_line.detect do |line|
        rx.match line
      end
      raise CommandNotFound, "Did not find a suffixed command in file `#{fd.path}`" unless command
      command.gsub!(rx, '') if @config.stripMatched

      applyCommand command, fd
    end

    # Find a given regex in a file and apply the build command when matched
    # Raises CommandNotFound if no command was found in a file
    def runRegex fd
      rx = @config.searchArgument
      command = fd.each_line.detect do |line|
        rx.match line
      end
      raise CommandNotFound, "Did not find a regex-ed command in file `#{fd.path}`" unless command
      command.gsub!(rx, '') if @config.stripMatched

      applyCommand command, fd
    end

    # Run the second line of code. This is the default option.
    def runSecondLine fd
      isEncodingLine = /coding[:=]\s*([-\w.]+)/
      fd.gets
      secondLine = fd.gets

      raise CommandNotFound, "There wasn't enough data in the file `#{fd.path}` for two lines!" if $_.nil?

      if isEncodingLine =~ secondLine
        secondLine = fd.gets
        raise CommandNotFound, "There wasn't enough data in the file `#{fd.path}` for three lines!" if $_.nil?
      end

      # Strip stuff until the first whitespace
      command = secondLine[(secondLine =~ /\s/)...secondLine.length].strip

      applyCommand command, fd
    end
  end
  class CommandNotFound < StandardError; end
end