
enum RESPData: Equatable {
    case SimpleString(String)
    case Error(String)
    case Integer(Int)
    case BulkString(String)
    case Array([RESPData])
    case Null
}

extension RESPData {
    func encode() -> String {
        switch self {
        case .SimpleString(let string): return "+\(string)\r\n"
        case .Error(let string): return "-\(string)\r\n"
        case .Integer(let integer): return ":\(integer)\r\n"
        case .BulkString(let string): return "$\(string.count)\r\n\(string)\r\n"
        case .Array(let array): return "*\(array.count)\r\n\(array.map{ $0.encode() }.joined())"
        case .Null: return "$-1\r\n"
        }
    }
    
    func unpackStr() -> String {
        switch self {
        case .SimpleString(let string): return string
        case .BulkString(let string): return string
        default: fatalError("Expected command to be a simple or bulk string")
        }
    }
}
