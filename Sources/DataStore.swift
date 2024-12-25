import Dispatch

/// As we are using an `MultiThreadedEventLoopGroup` that uses more then 1 thread we need to ensure proper
/// synchronization on the shared state `data` in the `DataStore` (as the same instance is shared across
/// child `Channel`s). For this a serial `DispatchQueue` is used when we modify the shared state (the `Dictionary`).
class DataStore: @unchecked Sendable {
    
    // All access to data is guarded by dataSyncQueue.
    private let dataSyncQueue = DispatchQueue(label: "dataQueue")
    private var data: [String: String] = [:]
    
    func getItem(_ key: String) -> String? {
        data[key]
    }
    
    func setItem(_ key: String, value: String) {
        dataSyncQueue.async {
            self.data[key] = value
        }
    }
}
