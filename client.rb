#!/usr/bin/env ruby

require "async"
require "io/endpoint/unix_endpoint"
require "io/memory"
require "json"

# Maximum message size: 16KiB (should match server)
MAX_MESSAGE_SIZE = 16 * 1024

endpoint = IO::Endpoint.unix("wasm.ipc")
message = ARGV.pop

# Helper to send IO with ancillary data
def send_io_with_message(socket, io, message)
  # Create ancillary data with the IO object
  ancillary = Socket::AncillaryData.unix_rights(io)
  socket.sendmsg(message, 0, nil, ancillary)
end

# Helper to receive IO with ancillary data
def receive_io_with_message(socket)
  data, sender, flags, *ancillary_data = socket.recvmsg(1024, 0, 1024, scm_rights: true)
  
  io = nil
  ancillary_data.each do |ancillary|
    if ancillary.cmsg_is?(:SOCKET, :RIGHTS)
      ios = ancillary.unix_rights
      io = ios.first if ios && ios.any?
    end
  end
  
  [data, io]
end

Async do
  endpoint.connect do |stream|
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Convert to underlying socket for sendmsg/recvmsg
    socket = stream.to_io
    
    json_data = message
    actual_size = json_data.bytesize
    
    # Check if message fits in max size
    if actual_size > MAX_MESSAGE_SIZE
      puts "Error: Message too large (#{actual_size} bytes, max: #{MAX_MESSAGE_SIZE})"
      exit 1
    end
    
    # Create memory mapped buffer for the request (fixed size)
    request_handle = IO::Memory.new(MAX_MESSAGE_SIZE)
    
    begin
      # Write the JSON data to the memory buffer
      request_buffer = request_handle.map
      request_buffer.set_string(json_data, 0)
      
      # Send the request IO with message length
      request_message = "REQUEST:#{actual_size}"
      send_io_with_message(socket, request_handle.io, request_message)
      
      # Receive simple response message
      response_data = socket.recv(1024)
      
      # Parse response header
      if response_data.match(/^RESPONSE:(\d+)$/)
        result_length = $1.to_i
        
        # Read the result from the same buffer we sent (server reuses it)
        result = request_buffer.get_string(0, result_length)
        puts result
        
      elsif response_data.match(/^ERROR: (.+)$/)
        # Handle error messages from server
        error_message = $1
        puts "Server error: #{error_message}"
        exit 1
        
      else
        puts "Invalid response format: #{response_data}"
        exit 1
      end
      
    ensure
      # Cleanup request memory
      request_handle.close
    end

    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration = end_time - start_time
    $stderr.puts "Time taken: #{duration} seconds, #{1 / duration} calls per second"
  end
end
