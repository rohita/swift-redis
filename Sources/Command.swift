
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
        default: return .Error("ERR unknown command \(commandName)")
        }
    }
    
    private func handleSet(arguments: [RespType], dataStore: DataStore) -> RespType {
        if arguments.count >= 3 {
            dataStore.setItem(arguments[1].unpackStr(), value: arguments[2].unpackStr())
            return .SimpleString("OK")
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
}

