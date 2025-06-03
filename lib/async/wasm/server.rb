require "wasmtime"
require "io/memory"
require "json"

module Async
  module WASM
    class Server
      def initialize(endpoint, instance)
        @endpoint = endpoint
        @instance = instance
      end

      # Helper to send IO with ancillary data
      def send_io_with_message(socket, io, message)
        ancillary = Socket::AncillaryData.unix_rights(io)
        socket.sendmsg(message, 0, nil, ancillary)
      end

      # Helper to receive IO with ancillary data
      def receive_io_with_message(socket)
        data, sender, flags, *ancillary_data = socket.recvmsg(1024, 0, 1024, scm_rights: true)
        
        io = nil
        ancillary_data.each_with_index do |ancillary, i|
          if ancillary.cmsg_is?(:SOCKET, :RIGHTS)
            ios = ancillary.unix_rights
            io = ios.first if ios && ios.any?
          end
        end
        
        [data, io]
      end

      def run
        @endpoint.accept do |stream|
          # Convert to underlying socket for sendmsg/recvmsg
          socket = stream.to_io
          
          begin
            loop do
              # Receive request io with message length
              request_data, request_io = receive_io_with_message(socket)
              break unless request_io
              
              # Parse request header
              if request_data.match(/^REQUEST:(\d+)$/)
                message_length = $1.to_i
                
                # Get the maximum size of the underlying memory using stat
                max_buffer_size = request_io.stat.size
                
                # Validate message size against actual buffer capacity
                if message_length > max_buffer_size
                  # Send error for oversized message directly over socket
                  error_message = "ERROR: Message too large (#{message_length} bytes, max: #{max_buffer_size})"
                  socket.send(error_message, 0)
                  next
                end
                
                # Create IO from received io and map buffer
                request_buffer = IO::Buffer.map(request_io, message_length)
                
                # Read the message data
                message_data = request_buffer.get_string(0, message_length)
                
                begin
                  # Parse and process the message
                  message = JSON.parse(message_data)
                  result = @instance.invoke(*message)
                  
                  result_data = JSON.generate(result)
                  actual_size = result_data.bytesize
                  
                  # Check if response fits in actual buffer size
                  if actual_size > max_buffer_size
                    # Response too large, send error directly over socket
                    error_message = "ERROR: Response too large (#{actual_size} bytes, max: #{max_buffer_size})"
                    socket.send(error_message, 0)
                    next
                  end
                  
                  # Reuse the request buffer for the response
                  request_buffer.set_string(result_data, 0)
                  
                  # Send simple response message (no need to send IO back)
                  response_message = "RESPONSE:#{actual_size}"
                  socket.send(response_message, 0)
                  
                rescue JSON::ParserError => e
                  # Send JSON parsing error directly over socket
                  error_message = "ERROR: Invalid JSON - #{e.message}"
                  socket.send(error_message, 0)
                  
                rescue => e
                  # Send general execution error directly over socket
                  error_message = "ERROR: Execution failed - #{e.message}"
                  socket.send(error_message, 0)
                end
                
                # Cleanup request
                request_buffer.free if request_buffer.respond_to?(:free)
                request_io.close unless request_io.closed?
              else
                # Invalid request format
                break
              end
            end
          rescue Errno::ECONNRESET, Errno::EPIPE
            # Client disconnected, clean exit
          rescue => error
            Console.error(self, error)
          end
        end
      end
    end
  end
end