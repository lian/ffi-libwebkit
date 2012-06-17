#!/usr/bin/ruby
$:.unshift( File.join(File.dirname(__FILE__),'lib') )

require "ffi-webkit/browser"

b = FFI::Webkit::Browser.new

b.add_keys({
  "o"   => :UriOpen,
  "O"   => :UriEdit,
  "p"   => :UriPaste,
  "i"   => :ModeInsert,
  "b"   => :BrowserBack,
  "m"   => :BrowserForward,
  "ZZ"  => :Quit,
  "Esc" => :ModeCommand
})

b.uri = ARGV[0] || "http://google.com"
#b.run
b.step_loop