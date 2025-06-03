# Async WASM IPC Implementation

This project implements high-performance inter-process communication (IPC) between a Ruby client and WASM server using Unix Domain Sockets with shared memory buffers.

## Architecture

The implementation uses a hybrid approach combining:
- **Unix Domain Sockets (UDS)** for control messages and file descriptor passing
- **Shared memory buffers** for efficient data transfer without copying

## Protocol

### Request Flow
1. Client creates a memory-mapped buffer using `IO::Memory.new(size)`
2. Client writes JSON request data to the buffer
3. Client sends the buffer's file descriptor via UDS with message: `"REQUEST:length"`
4. Server receives the file descriptor and maps the same memory buffer
5. Server reads the request data directly from shared memory

### Response Flow
1. Server processes the request and generates response
2. Server **reuses the same buffer** to write the response data
3. Server sends simple notification: `"RESPONSE:length"`
4. Client reads the response from its original buffer

### Error Handling
- Oversized requests/responses: `"ERROR: Message too large (size bytes, max: limit)"`
- JSON parsing errors: `"ERROR: Invalid JSON - details"`
- Execution errors: `"ERROR: Execution failed - details"`

## Key Benefits

- **Zero-copy data transfer**: Data is written once and read from shared memory
- **Dynamic buffer sizing**: Server detects buffer capacity using `io.stat.size`
- **Memory efficiency**: Single buffer reused for request and response
- **Simple protocol**: Minimal overhead with direct error messaging

## Files

- `lib/async/wasm/server.rb` - WASM server with IPC handling
- `client.rb` - Ruby client for sending requests
- Both support automatic buffer size detection and comprehensive error handling

## Usage

### Running the Server
```bash
# Start the WASM server listening on Unix socket
./server.rb
```

### Running the Client
```bash
# Send JSON request to server
$ ./client.rb '["is_even", 2]'
1
Time taken: 0.0010860000038519502 seconds, 920.8103098094701 calls per second
```
