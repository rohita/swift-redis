import Foundation

struct Protocol {
    func extractFrame(from buffer: Data) -> (RESPData, Int) {
        let (payload, size) = readUntilCrlf(from: buffer)
        guard let payload else {
            return (RESPData.Null, 0)
        }
        
        switch buffer[0].toChar() {
        case "+": return (.SimpleString(payload.toString()), size)
        case "-": return (.Error(payload.toString()), size)
        case ":": return (.Integer(Int(payload.toString())!), size)
        case "$": return parseBulkString(from: buffer)
        case "*": return parseArray(from: buffer)
        default: return (RESPData.Null, 0)
        }
    }
    
    func parseBulkString(from buffer: Data) -> (RESPData, Int) {
        let (payload, bytesConsumed) = readUntilCrlf(from: buffer)
        guard let payload else {
            return (.Null, 0)
        }
        
        guard let bulkStringLength = Int(payload.toString()) else {
            return (.Null, 0)
        }
        
        if bulkStringLength == -1 {
            return (.Null, 0)
        }
        
        let endOfBulkStringIndex = bytesConsumed + bulkStringLength
        if endOfBulkStringIndex >= buffer.count {
            return (.Null, 0)
        }
        
        return (.BulkString(Data(buffer[bytesConsumed..<endOfBulkStringIndex]).toString()), endOfBulkStringIndex+2)
    }
    
    func parseArray(from buffer: Data) -> (RESPData, Int) {
        var (payload, bytesConsumed) = readUntilCrlf(from: buffer)
        guard let payload else {
            return (.Null, 0)
        }
        
        guard let arrayLength = Int(payload.toString()) else {
            return (.Null, 0)
        }
        
        if arrayLength == -1 {
            return (.Null, 0)
        }
        
        if arrayLength == 0 {
            return (.Array([]), bytesConsumed)
        }
        
        var array: [RESPData] = []
        for _ in 0..<arrayLength {
            let (arrayItem, len) = extractFrame(from: Data(buffer[bytesConsumed...]))
            
            if arrayItem == .Null {
                return (.Null, 0)
            }
            
            bytesConsumed += len
            array.append(arrayItem)
        }
        
        return (.Array(array), bytesConsumed)
    }
    
    func readUntilCrlf(from buffer: Data) -> (Data?, Int) {
        var data: Data = Data()
        for i in 2..<buffer.count {
            if buffer[i-1] == "\r" && buffer[i] == "\n" {
                return (data, i+1)
            }
            data.append(buffer[i-1])
        }
        return (nil, 0)
    }
}

extension UInt8 {
    func toChar() -> Character {
        Character(UnicodeScalar(self))
    }
    
    static func ==(lhs: UInt8, rhs: Character) -> Bool {
        lhs.toChar() == rhs
    }
}

extension Data {
    func toString() -> String {
        String(decoding: self, as: UTF8.self)
    }
}
