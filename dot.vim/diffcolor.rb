#!/usr/bin/env ruby
=begin
= diffcolor.rb
colorize diff like vim.
and show \r and other space characters.

== usage
  env LANG=C svn diff | diffcolor.rb | lv -c
  svk diff | diffcolor.rb | less -R

== License
Copyright (c) 2006 Kazuhiro NISHIYAMA

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
=end

ARGF.each do |line|
  color = 0
  case line
  when /^[\-+]{3}/, /^\w/
    color = 32
  when /^@/
    color = 33
  when /^-/
    color = 31
  when /^\+/
    color = 36
  else
    color = 0
  end
  print "\e[#{color}m"
  line.gsub!(/\r/) { "\e[34;4m\\r\e[0m" }
  #line.gsub!(/[^\n\S]+/) { "\e[34;4m#{$&}\e[0;#{color}m" }
  puts line
end
print "\e[0m"
