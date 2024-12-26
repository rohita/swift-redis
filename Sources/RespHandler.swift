import Foundation

struct RespHandler {
    func parse(from buffer: Data) -> (RespType, Int) {
        let (payload, size) = readUntilCrlf(from: buffer)
        guard let payload else {
            return (RespType.Null, 0)
        }
        
        switch buffer[0].toChar() {
        case "+": return (.SimpleString(payload.toString()), size)
        case "-": return (.Error(payload.toString()), size)
        case ":": return (.Integer(Int(payload.toString())!), size)
        case "$": return parseBulkString(from: buffer)
        case "*": return parseArray(from: buffer)
        default: return (RespType.Null, 0)
        }
    }
    
    private func parseBulkString(from buffer: Data) -> (RespType, Int) {
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
    
    private func parseArray(from buffer: Data) -> (RespType, Int) {
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
        
        var array: [RespType] = []
        for _ in 0..<arrayLength {
            let (arrayItem, len) = parse(from: Data(buffer[bytesConsumed...]))
            
            if arrayItem == .Null {
                return (.Null, 0)
            }
            
            bytesConsumed += len
            array.append(arrayItem)
        }
        
        return (.Array(array), bytesConsumed)
    }
    
    private func readUntilCrlf(from buffer: Data) -> (Data?, Int) {
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


