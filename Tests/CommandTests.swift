import Testing
import Foundation
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
        
        // Set with Expire Errors
        (.Array([.BulkString("set"), .SimpleString("key"), .SimpleString("value"), .SimpleString("ex")]), .Error("ERR syntax error")),
        (.Array([.BulkString("set"), .SimpleString("key"), .SimpleString("value"), .SimpleString("px")]), .Error("ERR syntax error")),
        (.Array([.BulkString("set"), .SimpleString("key"), .SimpleString("value"), .SimpleString("foo")]), .Error("ERR syntax error")),
        
    ]) func testHandleCommand(command: RespType, expected: RespType) {
        #expect(Command().handle(command, dataStore: dataStore) == expected)
    }
    
    @Test func testGetWithNoExpiry() {
        Command().handle(.Array([.BulkString("set"), .SimpleString("key"), .SimpleString("value")]), dataStore: dataStore)
        sleep(1)
        #expect(Command().handle(.Array([.BulkString("get"), .SimpleString("key")]), dataStore: dataStore) == .BulkString("value"))
    }
    
    @Test func testGetWithExpiry() {
        let key = "key"
        let value = "value"
        let px = 100
        
        let pxCommand = RespType.Array([
            .BulkString("set"),
            .SimpleString(key),
            .SimpleString(value),
            .BulkString("px"),
            .BulkString("\(px)")
        ])
        
        let setResult = Command().handle(pxCommand, dataStore: dataStore)
        sleep(1)
        let getResult = Command().handle(.Array([.BulkString("get"), .SimpleString(key)]), dataStore: dataStore)

        #expect(setResult == .SimpleString("OK"))
        #expect(getResult == .Null)
    }
    
    @Test func testSetWithExpiryEx() {
        let key = "key"
        let value = "value"
        let ex = 1
        
        let exCommand = RespType.Array([
            .BulkString("set"),
            .SimpleString(key),
            .SimpleString(value),
            .BulkString("ex"),
            .BulkString("\(ex)")
        ])
        let expectedExpiry = Date().msSinceEpoch + UInt64(ex * 1000)
        let result = Command().handle(exCommand, dataStore: dataStore)
        let getResult = Command().handle(.Array([.BulkString("get"), .SimpleString(key)]), dataStore: dataStore)
        let stored = dataStore.data[key]!
        let diff = stored.expiryTimeSinceEpochMs - expectedExpiry

        #expect(result == .SimpleString("OK"))
        #expect(getResult == .BulkString(value))
        #expect(stored.value == value)
        #expect(diff == 0)
    }
    
    @Test func testSetWithExpiryPx() {
        let key = "key"
        let value = "value"
        let px = 100
        
        let pxCommand = RespType.Array([
            .BulkString("set"),
            .SimpleString(key),
            .SimpleString(value),
            .BulkString("px"),
            .BulkString("\(px)")
        ])
        let expectedExpiry = Date().msSinceEpoch + UInt64(px)
        let result = Command().handle(pxCommand, dataStore: dataStore)
        let stored = dataStore.data[key]!
        let diff = stored.expiryTimeSinceEpochMs - expectedExpiry

        #expect(result == .SimpleString("OK"))
        #expect(stored.value == value)
        #expect(diff == 0)
    }
    
}

