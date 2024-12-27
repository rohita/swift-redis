import Testing
import Foundation
@testable import SwiftRedis

struct CommandTests {
    
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
        (.Array([.BulkString("get"), .SimpleString("key")]), .BulkString("value")),
        (.Array([.BulkString("get"), .SimpleString("key_notExist")]), .Null),
        
        // Set with Expire Errors
        (.Array([.BulkString("set"), .SimpleString("key"), .SimpleString("value"), .SimpleString("ex")]), .Error("ERR syntax error")),
        (.Array([.BulkString("set"), .SimpleString("key"), .SimpleString("value"), .SimpleString("px")]), .Error("ERR syntax error")),
        (.Array([.BulkString("set"), .SimpleString("key"), .SimpleString("value"), .SimpleString("foo")]), .Error("ERR syntax error")),
        
        // Unrecognised Command
        (.Array([.BulkString("foo")]), .Error("ERR unknown command 'foo', with args beginning with: ''")),
        (.Array([.BulkString("foo"), .SimpleString("key")]), .Error("ERR unknown command 'foo', with args beginning with: 'key'")),
        (.Array([.BulkString("foo"), .SimpleString("key bar")]), .Error("ERR unknown command 'foo', with args beginning with: 'key bar'")),
        
        // Exists Tests
        (.Array([.BulkString("exists")]), .Error("ERR wrong number of arguments for 'exists' command")),
        (.Array([.BulkString("exists"), .SimpleString("invalid key")]), .Integer(0)),
        (.Array([.BulkString("exists"), .SimpleString("key")]), .Integer(1)),
        (.Array([.BulkString("exists"), .SimpleString("invalid key"), .SimpleString("key")]), .Integer(1)),
        
        // Del Tests
        (.Array([.BulkString("del")]), .Error("ERR wrong number of arguments for 'del' command")),
        (.Array([.BulkString("del"), .SimpleString("del key")]), .Integer(1)),
        (.Array([.BulkString("del"), .SimpleString("invalid key")]), .Integer(0)),
        (.Array([.BulkString("del"), .SimpleString("del key2"), .SimpleString("invalid key")]), .Integer(1)),
        
        // Incr Tests
        (.Array([.BulkString("incr")]), .Error("ERR wrong number of arguments for 'incr' command")),
        (.Array([.BulkString("incr"), .SimpleString("key")]), .Error("ERR value is not an integer or out of range")),
                
        // Decr Tests
        (.Array([.BulkString("decr")]), .Error("ERR wrong number of arguments for 'decr' command")),
        (.Array([.BulkString("decr"), .SimpleString("key")]), .Error("ERR value is not an integer or out of range")),
        
    ]) func testHandleCommand(command: RespType, expected: RespType) {
        let dataStore = DataStore()
        dataStore.setItem("key", value: "value")
        dataStore.setItem("del key", value: "value")
        dataStore.setItem("del key2", value: "value")
        #expect(Command().handle(command, dataStore: dataStore) == expected)
    }
    
    @Test func testIncrWithValidKey() {
        let dataStore = DataStore()
        let result1 = Command().handle(.Array([.BulkString("incr"), .SimpleString("ki")]), dataStore: dataStore)
        let result2 = Command().handle(.Array([.BulkString("incr"), .SimpleString("ki")]), dataStore: dataStore)
        #expect(result1 == .Integer(1))
        #expect(result2 == .Integer(2))
    }
    
    @Test func testDecrWithValidKey() {
        let dataStore = DataStore()
        let result1 = Command().handle(.Array([.BulkString("incr"), .SimpleString("kd")]), dataStore: dataStore)
        let result2 = Command().handle(.Array([.BulkString("incr"), .SimpleString("kd")]), dataStore: dataStore)
        let result3 = Command().handle(.Array([.BulkString("decr"), .SimpleString("kd")]), dataStore: dataStore)
        let result4 = Command().handle(.Array([.BulkString("decr"), .SimpleString("kd")]), dataStore: dataStore)
        #expect(result1 == .Integer(1))
        #expect(result2 == .Integer(2))
        #expect(result3 == .Integer(1))
        #expect(result4 == .Integer(0))
    }
    
    

    @Test func testGetWithExpiry() {
        let dataStore = DataStore()
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
        let dataStore = DataStore()
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
        let dataStore = DataStore()
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

