#!/usr/bin/env ruby
# echo yay! you ran inmake on inmake itself in default mode!
# Option parsing!

require 'optparse'

opts = {}

OptionParser.new do |parser|
  
  parser.banner = "Inline Command Runner\n"\
                  "Runs commands directly embedded inside source code.\n\n" \
                  "Usage: #{$0} [options...]\n" \
                  "Use #{$0} --help to list all command line options."
  
  parser.on("-f", "--file FILE", "Specify the file in which the build string "\
                                 "is found") do |file|
    opts[:filename] = file
  end
  
  parser.on("-p", "--prefix PREFIX", "Specify the build string's prefix.") do |prefix|
    opts[:prefix] = prefix
    opts[:mode] = :prefix
  end

  parser.on("-m","--postfix POSTFIX", "Specify the build string's postfix.") do |postfix|
    opts[:postfix] = postfix
    opts[:mode] = :postfix
  end

  # 
  # Regexp magic
  # 

  parser.on("-r", "--regex REGEX", "Specify a regex to match the build string's line.") do |regex|
    begin
      re = RegExp.compile regex
      opts[:regex] = re
      opts[:mode] = regex
    rescue
      abort "\"#{regex}\" is not a valid regular expression! Aborting."
    end
  end

  parser.on("--[no-]strip-matched", "Strip -r regex matches from the build"\
                                    "string, globally (gsub!)") do |sm|
    opts[:sm] = sm
  end

  #
  # Variable magic
  #

  parser.on("-a", "--add-var KEY=VALUE", "Add {{keys}} to be substituted "\
                                         "for values inside the build "\
                                         "string. Note: custom vars are "\
                                         "always all-caps!") do |vars|
    opts[:vars] ||= Hash.new
    key, value = vars.split '='
    abort "variable " + vars + " was invalid: variables must "\
                               "be KEY=VALUE" unless key[0] and key[1]
    opts[:vars][key.upcase] = value
  end
  
  parser.on("--no-vars", "Do /not/ replace special variables inside the "\
                         "build string.") do |nv|
    opts[:novars] = nv
  end
  
  parser.on("--list-vars", "List all 'special variables' the program defines.") do
    puts %{Builtin variables:
  {{f}} : the exact file name of your file, eg `/usr/bin/ruby`.
  {{bn}} : the file's base name, eg `ruby`.
  {{dn}} : the file's directory name, eg `/usr/bin`.}

    if opts[:vars]
      puts "-a variables:"
      opts[:vars].each do |k, v|
        puts "  {{"+k.to_s+"}} -> " + v
      end
    end

    exit 0
  end


end.parse!



# Stopped parsing arguments, we're ready to open the file.
# But first, checks!

abort "Missing the -f FILE argument!\n"\
      "See #{$0} --help for help. Aborting." unless opts[:filename]

abort "\"#{opts[:filename]}\" doesn't exist!" unless File.exist? opts[:filename]
abort "\"#{opts[:filename]}\" is not a file!" unless File.file? opts[:filename]
abort "\"#{opts[:filename]}\" is unreadable!" unless File.readable? opts[:filename]


# Set up substitutions
subs = {
  f: opts[:filename],
  bn: File.basename(opts[:filename]),
  dn: File.dirname(opts[:filename])
}
subs = subs.merge opts[:vars] if opts[:vars]

# 
# Okay now for the ACTUAL IMPLEMENTATION!
# 

File.open(opts[:filename]) do |f|

  command = ""
  rx = nil

  # mode #1: prefixed with --prefix
  if opts[:prefix]
    # REGEXES SUPPORT STRING INTERPOLATION AAHHH RUBY IS AWESOME
    rx = /^\s*#{opts[:prefix]}\s*/
    command = f.each_line.detect do |line|
      rx.match line
    end
    # let's cut our prefix off before shipping the command off to system
    command.gsub!(rx, '')

  # mode #2: postfixed with --postfix
  elsif opts[:postfix]
    rx = /#{opts[:postfix]}\s*$/
    command = f.each_line.detect do |line|
      rx.match line
    end
    # let's cut off our postfix as well as our prefix
    command.gsub!(rx, '')
    command = command[(command =~ /\s/)...command.length].strip
    

  # mode #3: manually regexing!
  elsif opts[:regex]
    rx = opts[:regex]
    command = f.each_line.detect do |line|
      rx.match line
    end
    command = command[(command =~ /\s/)...command.length].strip
    # allow User to strip if User wants to
    command.gsub!(rx, '') if opts[:sm]

  # mode #4: automatically use 2nd or 3rd line (if coding=... matches!)
  else
    rx = /coding[:=]\s*([-\w.]+)/
    
    # eat the first line
    f.gets
    # get second or third depending on match
    command = f.gets
    if rx.match command.chomp
      command = f.gets
    end
    # slice until first whitespace and then strip the whitespace both ways
    command = command[(command =~ /\s/)...command.length].strip
  end

  # well, we're done here, now for system!

  # but wait!
  # we have special variables to replace!
  subs.each do |k, v|
    command.gsub! "{{"+k.to_s+"}}", v
  end unless opts[:novars]

  # ok now we're done
  system command 
  puts command
end



# inmake.rb
# =========
# 
# A command-line tool to sorta replace Makefiles, and to make my using Sublime 
# Text's build features a slight bit simpler. It runs on source code files, 
# looking for a code comment that might be considered the build command for this 
# file. Then, it runs the command in the shell via system().
# 
# For further purposes, the build command / code comment is called a build
# string. 
# 
# Modes
# -----
# 
# The program can run in different 'modes' where the way it looks for the build
# string slightly vary. For example, in **prefix mode**, you can specify a 
# sequence to be searched for in the *start* of the string, and in **postfix 
# mode** you can specify a search for the *end* of the string. 
# 
# There's also **default mode**, which uses the second code line as the shell 
# command (while also stripping leading non-whitespace, followed by whitespace).
# As an exception, when the second line is used to specify encoding (for example
# in Python scripts where the first line is the shebang line), the third line 
# will be used instead.
# 
# The last running mode is for the advanced user, and it lets you specify your 
# very own **regular expression**, so you can search for whatever you like. 
# You'll also have the option of removing the matches from the build string 
# before running.
# 
# Variables
# ---------
# 
# Aside from different run modes, you can specify key-value pairs that will be
# used as 'variables' inside the build string. For example, by passing
# `-a AWESOME=1` to inmake, you can use `{{AWESOME}}` inside the build string,
# which will be replaced with `1` for every occurrence.
# 
# There are also some default variables: 
# 
# `{{f}}` is the full filename passed into inmake.
# `{{bn}}` is that file's base name. (the filename without leading directories)
# `{{dn}}` is that file's directory name. (just the directory)
# 
# Usage
# -----
# 
# ruby $0 [options...],
#   where options are:
# 
#   -f FILE, --file FILE
#           Specify the file in which the build string is found
#   
#   -p PREFIX, --prefix PREFIX
#           Specify the build string's prefix.
# 
#   -m POSTFIX, --postfix POSTFIX
#           Specify the build string's postfix.
# 
#   -r REGEX, --regex REGEX
#           Specify a regex to match the build string.
# 
#   --[no-]strip-matched
#           Strip regex matches (-r) from the build string.
#
#   -a KEY=VALUE, --add KEY=VALUE
#           Add key/value pairs to variables.
#
#   --no-vars
#           Disable all variables.
# 
#   --list-vars
#           Print currently defined variables, and exit.
#
# by boxmein, 2014
# MIT licensed <3
# 