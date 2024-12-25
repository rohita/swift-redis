import Testing
@testable import SwiftRedis

struct CommandTests {
    var dataStore: DataStore = DataStore()
    
    @Test(arguments: [
        // Echo Tests
        (RespType.Array([.BulkString("ECHO")]), RespType.Error("ERR wrong number of arguments for 'echo' command")),
        (.Array([.BulkString("echo"), .BulkString("Hello")]), .BulkString("Hello")),
        (.Array([.BulkString("echo"), .BulkString("Hello"), .BulkString("World")]), .Error("ERR wrong number of arguments for 'echo' command")),
        
        // Ping Tests
        (.Array([.BulkString("ping")]), .SimpleString("PONG")),
        (.Array([.BulkString("ping"), .BulkString("Hello")]), .BulkString("Hello")),
        (.Array([.BulkString("ping"), .BulkString("Hello"), .BulkString("Hello")]), .Error("ERR wrong number of arguments for 'ping' command")),
        
        // Set Tests
        (.Array([.BulkString("set")]), .Error("ERR wrong number of arguments for 'set' command")),
        (.Array([.BulkString("set"), .SimpleString("key")]), .Error("ERR wrong number of arguments for 'set' command")),
        (.Array([.BulkString("set"), .SimpleString("key"), .SimpleString("value")]), .SimpleString("OK")),
        
        // Get Tests
        (.Array([.BulkString("get")]), .Error("ERR wrong number of arguments for 'get' command")),
        (.Array([.BulkString("get"), .SimpleString("key_notExist")]), .Null),
        
    ]) func testHandleCommand(command: RespType, expected: RespType) {
        #expect(Command().handle(command, dataStore: dataStore) == expected)
    }
    
    @Test func testGet() {
        Command().handle(.Array([.BulkString("set"), .SimpleString("key"), .SimpleString("value")]), dataStore: dataStore)
        #expect(Command().handle(.Array([.BulkString("get"), .SimpleString("key")]), dataStore: dataStore) == .BulkString("value"))
    }
}

