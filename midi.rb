#!/usr/bin/env ruby
$:.unshift File.join( File.dirname( __FILE__ ), '../lib')

require 'midi-eye'
require 'rubygems'
require 'eventmachine'
require 'em-websocket'

@input = UniMIDI::Input.gets

midi = MIDIEye::Listener.new(@input)

color = {1 => 0, 2 => 0, 3 => 0}

Thread.new {
  midi.listen_for(:class => [MIDIMessage::NoteOn, MIDIMessage::NoteOff, MIDIMessage::ControlChange]) do |event|
    color[event[:message].data[0]] = event[:message].data[1] * 2
    @channel.push "#%02X%02X%02X" % [color[1], color[2], color[3]]
  end
  midi.run
}
 
EventMachine.run {
  @channel = EM::Channel.new
  EventMachine::WebSocket.start(:host => "0.0.0.0", :port => 8080, :debug => true) do |ws|
    ws.onopen { @sid = @channel.subscribe{ |msg| ws.send msg }}
    ws.onclose   { @channel.unsubscribe(@sid) }
  end
  puts "Server started on http://0.0.0.0:8080/"
}

