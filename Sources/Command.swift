
struct Command {
    func handle(_ resp: RespType, dataStore: DataStore) -> RespType {
        let (commandName, arguments) = switch resp {
        case .Array(let array): (array[0].unpackStr(), array)
        default: fatalError("Unexpected command format")
        }
        
        switch commandName.uppercased() {
        case "ECHO": return self.handleEcho(arguments: arguments)
        case "PING": return self.handlePing(arguments: arguments)
        case "SET" : return self.handleSet(arguments: arguments, dataStore: dataStore)
        case "GET" : return self.handleGet(arguments: arguments, dataStore: dataStore)
        case "EXISTS" : return self.handleExists(arguments: arguments, dataStore: dataStore)
        case "DEL" : return self.handleDel(arguments: arguments, dataStore: dataStore)
        case "INCR" : return self.handleIncr(arguments: arguments, dataStore: dataStore)
        case "DECR" : return self.handleDecr(arguments: arguments, dataStore: dataStore)
        case "LPUSH" : return self.handleLpush(arguments: arguments, dataStore: dataStore)
        case "RPUSH" : return self.handleRpush(arguments: arguments, dataStore: dataStore)
        case "LRANGE" : return self.handleLrange(arguments: arguments, dataStore: dataStore)
        default: return self.handleUnrecognisedCommand(arguments: arguments)
        }
    }
    
    private func handleSet(arguments: [RespType], dataStore: DataStore) -> RespType {
        if arguments.count >= 3 {
            
            if arguments.count == 3 {
                dataStore.setItem(arguments[1].unpackStr(), value: arguments[2].unpackStr())
                return .SimpleString("OK")
            } else if arguments.count == 5 {
                let expiryMode = arguments[3].unpackStr()
                guard let expiryTime = Int(arguments[4].unpackStr()) else {
                    return .Error("ERR value is not an integer or out of range")
                }
                
                switch expiryMode.uppercased() {
                case "EX": dataStore.setItem(arguments[1].unpackStr(), value: arguments[2].unpackStr(), expiryTimeMs: expiryTime * 1000)
                case "PX": dataStore.setItem(arguments[1].unpackStr(), value: arguments[2].unpackStr(), expiryTimeMs: expiryTime)
                default: return .Error("ERR invalid expiry mode")
                }
                
                return .SimpleString("OK")
            }
            
            return .Error("ERR syntax error")
        } else {
            return .Error("ERR wrong number of arguments for 'set' command")
        }
    }
    
    private func handleGet(arguments: [RespType], dataStore: DataStore) -> RespType {
        if arguments.count == 2 {
            if let value = dataStore.getItem(arguments[1].unpackStr()) {
                return .BulkString(value)
            } else {
                return .Null
            }
        } else {
            return .Error("ERR wrong number of arguments for 'get' command")
        }
    }
    
    private func handleExists(arguments: [RespType], dataStore: DataStore) -> RespType {
        if arguments.count >= 2 {
            var count = 0
            for c in arguments[1...] {
                if dataStore.hasKey(c.unpackStr()) {
                    count += 1
                }
            }
            return .Integer(count)
        }
        return .Error("ERR wrong number of arguments for 'exists' command")
    }
    
    private func handleDel(arguments: [RespType], dataStore: DataStore) -> RespType {
        if arguments.count >= 2 {
            var count = 0
            for c in arguments[1...] {
                if dataStore.hasKey(c.unpackStr()) {
                    dataStore.remove(c.unpackStr())
                    count += 1
                }
            }
            return .Integer(count)
        }
        return .Error("ERR wrong number of arguments for 'del' command")
    }
    
    private func handleIncr(arguments: [RespType], dataStore: DataStore) -> RespType {
        if arguments.count == 2 {
            let key = arguments[1].unpackStr()
            if let value = Int(dataStore.incr(key)) {
                return .Integer(value)
            }
            return .Error("ERR value is not an integer or out of range")
        }
        return .Error("ERR wrong number of arguments for 'incr' command")
    }
    
    private func handleDecr(arguments: [RespType], dataStore: DataStore) -> RespType {
        if arguments.count == 2 {
            let key = arguments[1].unpackStr()
            if let value = Int(dataStore.decr(key)) {
                return .Integer(value)
            }
            return .Error("ERR value is not an integer or out of range")
        }
        return .Error("ERR wrong number of arguments for 'decr' command")
    }
    
    private func handleLpush(arguments: [RespType], dataStore: DataStore) -> RespType {
        if arguments.count >= 2 {
            var totalCount: Int = 0
            let key = arguments[1].unpackStr()
            for c in arguments[2...] {
                guard let count = dataStore.prepend(key, value: c.unpackStr()) else {
                    return .Error("WRONGTYPE Operation against a key holding the wrong kind of value")
                }
                totalCount = count
            }
            return .Integer(totalCount)
        }
        return .Error("ERR wrong number of arguments for 'lpush' command")
    }
    
    private func handleRpush(arguments: [RespType], dataStore: DataStore) -> RespType {
        if arguments.count >= 2 {
            var totalCount: Int = 0
            let key = arguments[1].unpackStr()
            for c in arguments[2...] {
                guard let count = dataStore.append(key, value: c.unpackStr()) else {
                    return .Error("WRONGTYPE Operation against a key holding the wrong kind of value")
                }
                totalCount = count
            }
            return .Integer(totalCount)
        }
        return .Error("ERR wrong number of arguments for 'rpush' command")
    }
    
    private func handleLrange(arguments: [RespType], dataStore: DataStore) -> RespType {
        if arguments.count == 4 {
            let key = arguments[1].unpackStr()
            let start = Int(arguments[2].unpackStr())!
            let stop = Int(arguments[3].unpackStr())!
            
            guard let range = dataStore.lrange(key, start: start, stop: stop) else {
                return .Error("WRONGTYPE Operation against a key holding the wrong kind of value")
            }
            
            return .Array(range.map { .BulkString($0) })
        }
        return .Error("ERR wrong number of arguments for 'lrange' command")
    }
    
    private func handleEcho(arguments: [RespType]) -> RespType {
        if arguments.count == 2 {
            return .BulkString(arguments[1].unpackStr())
        } else {
            return .Error("ERR wrong number of arguments for 'echo' command")
        }
    }
    
    private func handlePing(arguments: [RespType]) -> RespType {
        if arguments.count == 1 {
            return .SimpleString("PONG")
        } else if arguments.count == 2 {
            return .BulkString(arguments[1].unpackStr())
        } else {
            return .Error("ERR wrong number of arguments for 'ping' command")
        }
    }
    
    private func handleUnrecognisedCommand(arguments: [RespType]) -> RespType {
        let args = arguments[1...].map { $0.unpackStr() }.joined(separator: " ")
        return .Error("ERR unknown command '\(arguments[0].unpackStr())', with args beginning with: '\(args)'")
    }
}

