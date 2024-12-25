import Testing
@testable import SwiftRedis

struct RespTypeTests {
    @Test(arguments: [
        (RespType.SimpleString("OK"), "+OK\r\n"),
        (RespType.Error("Error"),   "-Error\r\n"),
        (RespType.Integer(100),     ":100\r\n"),
        (RespType.BulkString("This is a Bulk String"), "$21\r\nThis is a Bulk String\r\n"),
        (RespType.BulkString(""),   "$0\r\n\r\n"),
        (RespType.Array([]),        "*0\r\n"),
        (RespType.Null,             "$-1\r\n")
    ]) func testEncodeMessage(message: RespType, expected: String) {
        #expect(message.encode() == expected)
    }
}

