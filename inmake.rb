#!/usr/bin/env ruby

# inmake.rb
# =========
# 
#   A snippet to allow programs to specify inline short 'recipes' to run the
#   build scripts for the program. You do need to specify comment prefixes what
#   are used to discern build commands from other comments though. Do that with
#   the -p command line option.
#   
# Usage
# -----
# 
#   ruby $0 [options]
#   , where [options] are: 
#
#   -p, --prefix PREFIX (optional)
#       Specifies the comment prefix to look for at the start of each line.
#   -f, --file FILE (required)
#       Specifies the filename to actually compile.
# 
# Command syntax
# --------------
#
#   Great news! There is none. Just add a shell command to the targeted line.
#   We don't even fill in the filenames or anything.
#   Note only the first line from the top is run inside the script.
# 
# Extra
# -----
# 
#   Invoking inside a shell script is also a great idea to make it easier to use:
#   @ruby inmake.rb "$@" (for Windows, use %* instead of "$@")
# 
# 
# by boxmein, 2014
# MIT licensed <3
# 


require 'optparse'


opts = {}

OptionParser.new do |parser|
  
  parser.banner = "Inline Command Runner (Probably Called Matt)\nRuns commands directly embedded inside respective command scripts.\n\nUsage: #{$0} -p PREFIX -f FILE [options...]"


  parser.on("-p", "--prefix [PREFIX]", 
    "Specify the comment prefix to look for") do |prefix|

    opts[:prefix] = prefix
  end

  parser.on("-f", "--file FILE", 
    "Specify the file to compile (that rhymed!)") do |file|
    opts[:filename] = file
  end
end.parse!


if not opts[:filename]
  abort "Missing the file argument!\nSee #{$0} --help for help. Aborting."
end

if not ( File.exist? (opts[:filename]) and File.file? (opts[:filename]) and 
  File.readable? (opts[:filename]) )
  abort "\"#{opts[:filename]}\" was not a file or did not in fact exist! Aborting."
end



# 
# Enough of the option parsing!
# Runs a regex trying to find the command specified, then strips the data off
# and runs the command plainly.
# Simple enough, right?
# 

File.open(opts[:filename]) do |f|

  # the regex is constructed once to gsub with later
  rx = /^\s*#{opts[:prefix]}\s*/
  command = f.each_line.detect do |line|
    rx.match line
  end
  
  # let's cut our prefix off before shipping the command off to system
  command.gsub!(rx, '')
  puts command
  system(command)
end