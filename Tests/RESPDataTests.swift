import Testing
@testable import SwiftRedis

struct RESPDataTests {
    @Test(arguments: [
        (RESPData.SimpleString("OK"), "+OK\r\n"),
        (RESPData.Error("Error"),   "-Error\r\n"),
        (RESPData.Integer(100),     ":100\r\n"),
        (RESPData.BulkString("This is a Bulk String"), "$21\r\nThis is a Bulk String\r\n"),
        (RESPData.BulkString(""),   "$0\r\n\r\n"),
        (RESPData.Array([]),        "*0\r\n"),
        (RESPData.Null,             "$-1\r\n")
    ]) func testEncodeMessage(message: RESPData, expected: String) {
        #expect(message.encode() == expected)
    }
}

