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

            stream.puts(result.to_json)
          end
        end
      end
    end
  end
end