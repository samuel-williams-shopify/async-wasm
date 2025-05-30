#!/usr/bin/env async-service

require_relative "lib/async/wasm/environment"

service "executor" do
  include Async::WASM::Environment
end
