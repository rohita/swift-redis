import Testing
@testable import SwiftRedis

struct CommandsTests {
    @Test(arguments: [
        // Echo Tests
        (RESPData.Array([.BulkString("ECHO")]), RESPData.Error("ERR wrong number of arguments for 'echo' command")),
        (.Array([.BulkString("echo"), .BulkString("Hello")]), .BulkString("Hello")),
        (.Array([.BulkString("echo"), .BulkString("Hello"), .BulkString("World")]), .Error("ERR wrong number of arguments for 'echo' command")),
        
        // Ping Tests
        (.Array([.BulkString("ping")]), .SimpleString("PONG")),
        (.Array([.BulkString("ping"), .BulkString("Hello")]), .BulkString("Hello")),
        (.Array([.BulkString("ping"), .BulkString("Hello"), .BulkString("Hello")]), .Error("ERR wrong number of arguments for 'ping' command"))
        
    ]) func testHandleCommand(command: RESPData, expected: RESPData) {
        #expect(Command().handle(command: command) == expected)
    }
}

