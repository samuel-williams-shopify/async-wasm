require "wasmtime"

module Async
  module WASM
    class Server
      def initialize(endpoint, instance)
        @endpoint = endpoint
        @instance = instance
      end

      def run
        @endpoint.accept do |stream|
          while message = stream.gets
            message = JSON.parse(message)

            result = @instance.invoke(*message)

            # Write directly to the output stream:
            JSON::State.generate(result, {}, stream)
            stream.puts
          end
        end
      end
    end
  end
end