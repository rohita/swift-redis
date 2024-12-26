import Dispatch
import Foundation

/// As we are using an `MultiThreadedEventLoopGroup` that uses more then 1 thread we need to ensure proper
/// synchronization on the shared state `data` in the `DataStore` (as the same instance is shared across
/// child `Channel`s). For this a serial `DispatchQueue` is used when we modify the shared state (the `Dictionary`).
class DataStore: @unchecked Sendable {
    
    // All access to data is guarded by dataSyncQueue.
    private let dataSyncQueue = DispatchQueue(label: "dataQueue")
    var data: [String: DataEntry] = [:]
    
    func getItem(_ key: String) -> String? {
        if let item = self.data[key] {
            if item.expiryTimeSinceEpochMs > 0 && item.expiryTimeSinceEpochMs < Date().msSinceEpoch {
                return nil
            }
            return item.value
        }
        return nil
    }
    
    func setItem(_ key: String, value: String, expiryTimeMs: Int = 0) {
        dataSyncQueue.asyncAndWait {
            let calculatedExpiry = expiryTimeMs > 0 ? Date().msSinceEpoch + UInt64(expiryTimeMs) : 0
            self.data[key] = DataEntry(value: value, expiryTimeSinceEpochMs: calculatedExpiry)
        }
    }
    
    struct DataEntry {
        let value: String
        let expiryTimeSinceEpochMs: UInt64
    }
}


