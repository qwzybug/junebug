= JUNEBUG WIKI

* http://www.junebugwiki.com
* http://rubyforge.org/projects/junebug/
* tim.myrtle@gmail.com


== DESCRIPTION:

Junebug is a minimalist wiki, running on Camping.

This is an alpha release.  Use at your own risk.  Please do not use this for anything important.


== SYNOPSIS:
  
To create your Junebug wiki:

  % junebug testwiki

This creates a directory 'testwiki' with the necessary files.

  % cd testwiki
  % ruby wiki run

View your new wiki at: http://localhost:3301

If everything is running fine, you can set the wiki to run in the background.  Hit ctrl-C to kill the wiki, and then type

  % ruby wiki start

You can change default configuration (host, port, startpage, etc.. ) by editing the config.yml file.  For the changes to take effect, just restart the wiki:

  % ruby wiki restart


== REQUIREMENTS:

* Ruby and rubygems
* Sqlite3

_why has set up a page describing how to get sqlite3 set up on ruby for various platforms: http://code.whytheluckystiff.net/camping/wiki/BeAlertWhenOnSqlite3

Please follow the instructions _why has provided.  In particular, make sure that you have _why's latest sqlite3-ruby gem installed.


== INSTALL:

  % gem install junebug --include-dependencies


== NOTES:

Starting and stopping the wiki:

  % ruby wiki [start|stop|restart|run]


== CREDITS:

Thans to _why for camping http://code.whytheluckystiff.net/camping/wiki and his tepee wiki example which was the starting point for Junebug, and also to Chris Wanstrath for cheat http://cheat.errtheblog.com/ .


== LICENSE:

(The MIT License)

Copyright (c) 2006 Tim Myrtle

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
  
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
   
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


