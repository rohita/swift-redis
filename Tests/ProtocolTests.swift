import Testing
@testable import SwiftRedis

// generally recommended that a Swift structure or actor be used instead
// of a class because it allows the Swift compiler to better-enforce concurrency safety.
struct ProtocolTests {
    
    @Test(arguments: [
        // Test invalid Message
        ("PING\r\n", (RespType.Null, 0)),
        
        // Test cases for Simple Strings
        ("+Par",         (.Null, 0)),
        ("+OK\r\n",      (.SimpleString("OK"), 5)),
        ("+OK\r\n+Next", (.SimpleString("OK"), 5)),
        
        // Test cases for Errors
        ("-Err",                     (.Null, 0)),
        ("-Error Message\r\n",       (.Error("Error Message"), 16)),
        ("-Error Message\r\n+Other", (.Error("Error Message"), 16)),
        
        // Test cases for Integers
        (":10",         (.Null, 0)),
        (":100\r\n",    (.Integer(100), 6)),
        (":100\r\n+OK", (.Integer(100), 6)),
        
        // Test cases for Bulk Strings
        ("$5\r\nHel",                   (.Null, 0)),
        ("$5\r\nHello\r\n",             (.BulkString("Hello"), 11)),
        ("$12\r\nHello, World\r\n",     (.BulkString("Hello, World"), 19)),
        ("$12\r\nHello\r\nWorld\r\n",   (.BulkString("Hello\r\nWorld"), 19)),
        ("$0\r\n\r\n",                  (.BulkString(""), 6)),
        ("$-1\r\n",                     (.Null, 0)),
        
        // Test case for Arrays
        ("*0",                          (.Null, 0)),
        ("*0\r\n",                      (.Array([]), 4)),
        ("*-1\r\n",                     (.Null, 0)),
        ("*2\r\n$5\r\nhello\r\n$5\r\n", (.Null, 0)),
        
        ("*2\r\n$5\r\nhello\r\n$5\r\nworld\r\n",    (.Array([.BulkString("hello"), .BulkString("world")]), 26)),
        ("*2\r\n$5\r\nhello\r\n$5\r\nworld\r\n+OK", (.Array([.BulkString("hello"), .BulkString("world")]), 26)),
        ("*3\r\n:1\r\n:2\r\n:3\r\n",                (.Array([.Integer(1), .Integer(2), .Integer(3)]), 16)),
        ("*3\r\n:1\r\n:2\r\n:3\r\n+OK",             (.Array([.Integer(1), .Integer(2), .Integer(3)]), 16))
        
    ]) func testReadFrameSimpleString(input: String, expected: (RespType, Int)) {
        let buffer = input.data(using: .utf8)!
        let actual = RespHandler().parse(from: buffer)
        #expect(actual == expected)
    }
}
