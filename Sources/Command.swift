
struct Command {
    
    func handle(command resp: RESPData) -> RESPData {
        let (commandName, arguments) = switch resp {
        case .Array(let array): (array[0].unpackStr(), array)
        default: fatalError("Unexpected command format")
        }
        
        switch commandName.uppercased() {
        case "ECHO": return self.handleEcho(arguments: arguments)
        case "PING": return self.handlePing(arguments: arguments)
        default: return .Error("ERR unknown command \(commandName)")
        }
    }
    
    private func handleEcho(arguments: [RESPData]) -> RESPData {
        if arguments.count == 2 {
            return .BulkString(arguments[1].unpackStr())
        } else {
            return .Error("ERR wrong number of arguments for 'echo' command")
        }
    }
    
    private func handlePing(arguments: [RESPData]) -> RESPData {
        if arguments.count == 1 {
            return .SimpleString("PONG")
        } else if arguments.count == 2 {
            return .BulkString(arguments[1].unpackStr())
        } else {
            return .Error("ERR wrong number of arguments for 'ping' command")
        }
    }
}

