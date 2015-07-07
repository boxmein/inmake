# inmake

<a name="about"></a>

A multi-mode command line tool that lets you define your build / preprocessing 
shell commands inside the files themselves. I use it for programs I write in 
one file, via Sublime Text's build commands thing. 

## Modes

inmake supports different kinds of search modes when running a command, starting
from a simple prefix or suffix search ending with a full blown regular 
expression.

### Prefix mode

Looks for a character sequence at the start of the code line. Something like `#|`,
or `//!~$$`.Imagine a Python file called `asdf.py` that has a build command identified
by a prefix:

``` python
#!/usr/bin/python3
print "hello, this is code"
#| weird-python-compiler pythonfile.py -o out.css
```

Building it automatically is easy:

```
inmake -p "#|" asdf.py

```

### Suffix mode

Searches for something in the end of a code line to match the build string. However,
does not remove the suffix unless `--strip-matched` is also on the command line.

If this was called `hey.c`:

``` c
#include <stdio.h>
// gcc -o cfile.out cfile.c look_here_im_the_build_string
int main() { 
  printf("hello dude");
}
```

...then building it will look like:

```
inmake -s "look_here_im_the_build_string" --strip-matched hey.c
```


### Default/Second Line mode

inmake's second line mode is probably the most useful for a general use case. As
most programming languages will let you place a code comment on the second line
of the file, you can simply add a shell command there.

If a Jade source file called `index.jade` looks like this:

```jade
//- useful jade file that converts Markdown to a proper HTML page
//- jade index.jade
extends layout

block text
  include:md index.md
```

then the command to run "jade index.jade" would be:

```bash
inmake index.jade
```


### Regex mode

The last running mode is for the advanced user, and it lets you specify your 
very own **regular expression**, so you can search for whatever you like. 
You'll also have the option of removing the matches from the build string 
before running.

If a Python file called `blah.py` with a regex build command looks like this:

```python
#!/usr/bin/python3
# !!!weird-python-compiler!!! !!!pythonfile.py!!! !!!-o!!! !!!out.html!!!
print "hello"
```

the command to build it looks like that:

```bash
inmake -x "!!!" --strip-matched blah.py
```



## Variables

Aside from different run modes, you can specify key-value pairs that will be
used as 'variables' inside the build string. For example, by passing
`-a AWESOME=1` to inmake, you can use `{{AWESOME}}` inside the build string,
which will be replaced with `1` for every occurrence.

There are also some default variables: 

`{{f}}` is the filename of the current file.  
`{{bn}}` is that file's base name. (the filename without leading directories)  
`{{bn1}}` is that file's base name without a file extension. I've needed that a
lot so maybe you'll find use in this too!  
`{{ext}}` is the file's extension. eg ".rb"  
`{{dn}}` is that file's directory name. (just the directory)  
`{{mode}}` is the file's access mode (makes sense on a Linux machine)  
`{{mtime}}` is the file's last modified time as a Unix time.
`{{ctime}}` is the file's creation time as a Unix time.
`{{size}}` is the file's size in bytes.

So if a C source file called `advanced_virus.c` looks like this:

```c
// advanced virus
// gcc -o {{bn1}} {{f}} -fno-fast-math -std=c++15 -DLINES={{LINES}}
#include <stdio.h>
int main() { 
  int i = LINES; 
  while (lines --> 0) // C++15 standard "decrease-to" operator
    printf("lol you've been hacked!"); 
}
```

The appropriate command to build it would be:

```bash
inmake -a LINES=1500 advanced_virus.c
```


## Actual Usage

    inmake [options] [files]



### Options

`-f, --file FILENAME`: Specify a target file. You can also specify files by 
adding them after optional stuff.

`-a, --add-var KEY=VALUE`: Replaces `{{KEY}}` with `VALUE` in the build command 
before running it. 

`-p, --prefix PREFIX`: Build command is searched via a text line prefix.

`-s, --suffix SUFFIX`: Build command is searched via a text line suffix.

`-x, --regex REGEX`: Build command is searched via a regex applied to the text 
line

(The default search mode is "second-line" which is used when no other search 
mode is defined.)

`    --[no-]strip-matched`: Strip found regex matches before running the build 
command. **Default: false**

`    --[no-]ignore-nonmatched`: Silently continue if a file does not seem to 
have a build command. **Default: true**

`    --no-vars`: Disables all variables (even the default variables). **Default: false**

`-d, --dir-mode MODE`: Configure how directories are handled. Two possible 
values: `acceptDirs` and `ignoreDirs`. `acceptDirs` will make it so that 
directories passed to inmake are recursed and inmake is applied to all files 
inside. `ignoreDirs` skips all directories. **Default: acceptDirs**



### Files

Files can be either actually files or directories. Directories are handled 
according to the prevailing dir-mode.



<a name="sublime"></a>
## Sublime Text build script

This tool is an awesome companion to your text editor. I use Sublime Text, so 
I've also included the build script I use here. Make sure to replace $LOCATION
with where your script resides in.

``` json
{
  "shell_cmd": "inmake \"$file\""
}
``` 

