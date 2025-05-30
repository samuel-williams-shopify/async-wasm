require_relative "service"
require "io/endpoint/unix_endpoint"

module Async
  module WASM
    module Environment
      def endpoint
        IO::Endpoint.unix("wasm.ipc")
      end

      def container_options
        {}
      end

      def service_class
        Service
      end

      def wasm_path
        "service.wasm"
      end

      def wasm_engine
        Wasmtime::Engine.new
      end

      def wasm_store
        Wasmtime::Store.new(wasm_engine)
      end

      def wasm_module
        Wasmtime::Module.from_file(wasm_engine, wasm_path)
      end

      def wasm_instance
        Wasmtime::Instance.new(wasm_store, wasm_module, [])
      end

      def make_server(endpoint)
        Server.new(endpoint, wasm_instance)
      end
    end
  end
end
