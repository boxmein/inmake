#!/usr/bin/env ruby

# Option parsing!

require 'optparse'
opts = {}
OptionParser.new do |parser|
	
	parser.banner = "Inline Command Runner\nRuns commands directly embedded inside respective command scripts.\n\nUsage: #{$0} -p PREFIX -f FILE [options...]"
	
	parser.on("-f", "--file FILE", 
		"Specify the file to compile (that rhymed!)") do |file|
		opts[:filename] = file
	end
	
	parser.on("-p", "--prefix [PREFIX]", 
		"Specify the comment prefix to look for") do |prefix|
		opts[:prefix] = prefix
	end

	parser.on("-m","--moo [POSTFIX]", "Use a postfix instead of a prefix") do |postfix|
		opts[:postfix] = postfix
	end

	parser.on("-r", "--regex [REGEX]", "Set the regular expression yourself") do |regex|
		begin
			re = RegExp.compile regex
			opts[:regex] = re
		rescue
			abort "\"#{regex}\" is not a valid regex! Aborting."
		end
	end

	parser.on("--[no-]strip-matched", "Strip the things that matched with -r.") do |sm|
		opts[:sm] = sm
	end

end.parse!

# Checks!

if not opts[:filename]
	abort "Missing the file argument!\nSee #{$0} --help for help. Aborting."
end

if not ( File.exist? (opts[:filename]) and File.file? (opts[:filename]) and 
	File.readable? (opts[:filename]) )
	abort "\"#{opts[:filename]}\" was not a file or did not in fact exist! Aborting."
end



# 
# Okay now for the ACTUAL IMPLEMENTATION!
# 

File.open(opts[:filename]) do |f|

	command = ""
	rx = nil

	# mode #1: prefixed with --prefix
	if opts[:prefix]
		rx = /^\s*#{opts[:prefix]}\s*/
		command = f.each_line.detect do |line|
			rx.match line
		end
		# let's cut our prefix off before shipping the command off to system
		command.gsub!(rx, '')

	# mode #2: postfixed with --moo
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

	# mode #4: strictly 2nd or 3rd line (if coding=... matches!)
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
	puts command
	system command 
end



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
#   -f, --file FILE (required)
#       Specifies the filename to actually compile.
#
#   -p, --prefix PREFIX (optional)
#       Specifies the comment prefix to look for at the start of each line.
#       Strips away the prefix before applying.
#       e.g //# gcc -o test.exe test.c -DAWESOME=1
#       and ruby inmake.rb -f test.c -p '//#'
#
#   -m, --moo POSTFIX (optional)
#       Specifies a post-fix word to look for in order to find the command.
#       Strips away leading characters until whitespace.
#       e.g // gcc -o test.exe test.c -DAWESOME=1 moo
#       and ruby inmake.rb -f test.c -m moo
# 
#  -r, --regex REGEX (optional)
#       Specifies a regular expression to test every line against, if matched,
#       the first matched line is the command being run. Note however the code
#       will still have to be valid with the matched command inside it.
#       e.g aaaaaaaa gcc -o test.exe test.c -DAWESOME=1
#       and ruby inmake.rb -r "a{8}" -f test.c
#
#  --[no-]strip-matched (optional)
#       Makes -r strip the things it matched off the line. Basically, just runs
#       String#gsub(regex, '').
# 
#  If neither the prefix nor postfix argument are provided, then the second line
#  (or third, if second line is an encoding comment) will be used as the
#  command. As always, leading characters will be stripped before whitespace.
#  
#  If both are specified, then prefix prevails and is applied.  
# 
# 
# Command syntax
# --------------
#
#   Great news! There is none. Just add a shell command to the targeted line.
#   We don't even fill in the filenames or anything.
#   Note only the first line from the top is run inside the script.
# 
# 
# by boxmein, 2014
# MIT licensed <3
# 