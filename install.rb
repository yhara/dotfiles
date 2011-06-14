#!/usr/bin/env ruby


original = Dir["dot.*"]

if original.empty?
  puts "usage: "
  puts "  cd dotfiles"
  puts "  #{$0}"
  exit
end

original.each do |from|
  to = File.expand_path("~/#{from[/dot(.*)/, 1]}")
  from = File.expand_path(from)

  if File.symlink?(to)
    puts "symlink #{to} exists; overwriting"
    File.delete(to)
  elsif File.exist?(to) 
    puts "Error: #{to} exists"
    exit
  end
  
  cmd = "ln -s #{from} #{to}"
  puts cmd
  system cmd
end

