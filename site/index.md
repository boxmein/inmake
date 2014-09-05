inmake.rb
=========
<a name="about"></a>
A command-line tool to sorta replace Makefiles, and to make my using Sublime 
Text's build features a slight bit simpler. It runs on source code files, 
looking for a code comment that might be considered the build command for this 
file. Then, it runs the command in the shell via system().

For further purposes, the build command / code comment is called a build
string. 

Modes
-----

The program can run in different 'modes' where the way it looks for the build
string slightly vary. For example, in **prefix mode**, you can specify a 
sequence to be searched for in the *start* of the string, and in **postfix 
mode** you can specify a search for the *end* of the string. In both these 
modes, the found string is cut off before the command is executed.

For example:

``` python
#!/usr/bin/python3
print "hello, this is code"
#| weird-python-compiler pythonfile.py -o out.css
# inmake command line:
# ruby inmake.rb -f ~/pythonfile.py -p "#|"
```

``` c
#include <stdio.h>
// gcc -o cfile.out cfile.c look_here_im_the_build_string
int main() { 
  printf("hello dude");
}
// inmake command line: 
// ruby inmake.rb -f ~/cfile.c -m "look_here_im_the_build_string"
```

There's also **default mode**, which uses the second code line as the shell 
command (while also stripping leading non-whitespace, followed by whitespace).
*As an exception*, when the second line is used to specify encoding (for example
in Python scripts where the first line is the shebang line), the third line 
will be used instead.

**Note: you don't need to distinguish your build string in default mode!**

``` jade
// 
   jade index.jade
extends layout

block text
  include:md index.md
```

The last running mode is for the advanced user, and it lets you specify your 
very own **regular expression**, so you can search for whatever you like. 
You'll also have the option of removing the matches from the build string 
before running.

``` python
#!/usr/bin/python3
# !!!weird-python-compiler!!! !!!pythonfile.py!!! !!!-o!!! !!!out.html!!!
print "hello"
# inmake line: 
# ruby inmake.rb -f ~/pythonfile.py -r "!!!" --strip-matched
```


Variables
---------

Aside from different run modes, you can specify key-value pairs that will be
used as 'variables' inside the build string. For example, by passing
`-a AWESOME=1` to inmake, you can use `{{AWESOME}}` inside the build string,
which will be replaced with `1` for every occurrence.

There are also some default variables: 

`{{f}}` is the full filename passed into inmake.  
`{{bn}}` is that file's base name. (the filename without leading directories)  
`{{dn}}` is that file's directory name. (just the directory)

``` c
// lookie here, a C file!
// gcc -o {{bn}}.exe {{f}} -mwindows -std=c99
#include <windows.h>
LRESULT WINAPI WinMain( ...
```

Usage
-----

``` plain
ruby $0 [options...],
  where options are:

  -f FILE, --file FILE
          Specify the file in which the build string is found
  
  -p PREFIX, --prefix PREFIX
          Specify the build string's prefix.

  -m POSTFIX, --postfix POSTFIX
          Specify the build string's postfix.

  -r REGEX, --regex REGEX
          Specify a regex to match the build string.

  --[no-]strip-matched
          Strip regex matches (-r) from the build string.

  -a KEY=VALUE, --add KEY=VALUE
          Add key/value pairs to variables.

  --no-vars
          Disable all variables.

  --list-vars
          Print currently defined variables, and exit.
```

<a name="sublime"></a>
# Sublime Text build script

This tool is an awesome companion to your text editor. I use Sublime Text, so 
I've also included the build script I use here. Make sure to replace $LOCATION
with where your script resides in.

``` json
{
  "shell_cmd": "ruby $LOCATION/inmake.rb -f \"$file\""
}
``` 

# Source code

The source code will always just be accessible [here][gist]. 

[gist]: https://gist.github.com/boxmein/8303778

