#!/usr/bin/env ruby

require "async"
require "io/endpoint/unix_endpoint"

endpoint = IO::Endpoint.unix("wasm.ipc")
message = ARGV.pop

Async do
  endpoint.connect do |peer|
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    peer.puts message
    puts peer.gets

    end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    duration = end_time - start_time
    $stderr.puts "Time taken: #{duration} seconds, #{1 / duration} calls per second"
  end
end
