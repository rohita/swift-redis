import Dispatch
import Foundation
import Collections

/// As we are using an `MultiThreadedEventLoopGroup` that uses more then 1 thread we need to ensure proper
/// synchronization on the shared state `data` in the `DataStore` (as the same instance is shared across
/// child `Channel`s). For this a serial `DispatchQueue` is used when we modify the shared state (the `Dictionary`).
class DataStore: @unchecked Sendable {
    
    // All access to data is guarded by dataSyncQueue.
    private let dataSyncQueue = DispatchQueue(label: "dataQueue")
    private var data: [String: DataEntry] = [:]
    
    func hasKey(_ key: String) -> Bool {
        self.data[key] != nil
    }
    
    func remove(_ key: String) {
        dataSyncQueue.asyncAndWait {
            let _ = self.data.removeValue(forKey: key)
        }
    }
    
    func getRawData(_ key: String) -> DataEntry? {
        self.data[key]
    }
    
    func getItem(_ key: String) -> String? {
        if let item = self.data[key] {
            if item.expiryTimeSinceEpochMs > 0 && item.expiryTimeSinceEpochMs < Date().msSinceEpoch {
                self.remove(key)
                return nil
            }
            return item.value as? String
        }
        return nil
    }
    
    func setItem(_ key: String, value: String, expiryTimeMs: Int = 0) {
        dataSyncQueue.asyncAndWait {
            let calculatedExpiry = expiryTimeMs > 0 ? Date().msSinceEpoch + UInt64(expiryTimeMs) : 0
            self.data[key] = DataEntry(value: value, expiryTimeSinceEpochMs: calculatedExpiry)
        }
    }
    
    func incr(_ key: String) -> String? {
        let item = self.data[key] ?? DataEntry(value: "0", expiryTimeSinceEpochMs: 0)
        if let intValue = Int(item.value) {
            let newValue = String(intValue + 1)
            dataSyncQueue.asyncAndWait {
                self.data[key] = DataEntry(value: newValue, expiryTimeSinceEpochMs: item.expiryTimeSinceEpochMs)
            }
            return newValue
        }
        
        return nil
    }
    
    func decr(_ key: String) -> String? {
        let item = self.data[key] ?? DataEntry(value: "0", expiryTimeSinceEpochMs: 0)
        if let intValue = Int(item.value) {
            let newValue = String(intValue - 1)
            dataSyncQueue.asyncAndWait {
                self.data[key] = DataEntry(value: newValue, expiryTimeSinceEpochMs: item.expiryTimeSinceEpochMs)
            }
            return newValue
        }
        
        return nil
    }
    
    func prepend(_ key: String, value: String) -> Int? {
        let item = self.data[key] ?? DataEntry(value: Deque<String>(), expiryTimeSinceEpochMs: 0)
        if var dequeValue = item.value as? Deque<String> {
            dequeValue.prepend(value)
            dataSyncQueue.asyncAndWait {
                self.data[key] = DataEntry(value: dequeValue, expiryTimeSinceEpochMs: item.expiryTimeSinceEpochMs)
            }
            return dequeValue.count
        }
        return nil
    }
    
    func append(_ key: String, value: String) -> Int? {
        let item = self.data[key] ?? DataEntry(value: Deque<String>(), expiryTimeSinceEpochMs: 0)
        if var dequeValue = item.value as? Deque<String> {
            dequeValue.append(value)
            dataSyncQueue.asyncAndWait {
                self.data[key] = DataEntry(value: dequeValue, expiryTimeSinceEpochMs: item.expiryTimeSinceEpochMs)
            }
            return dequeValue.count
        }
        return nil
    }
    
    func lrange(_ key: String, start: Int, stop: Int) -> [String]? {
        let item = self.data[key] ?? DataEntry(value: Deque<String>(), expiryTimeSinceEpochMs: 0)
        if let dequeValue = item.value as? Deque<String> {
            if start > dequeValue.count {
                return []
            }
            
            var clampStart = start
            var clampedStop = stop
            if stop > dequeValue.count-1 {
                clampedStop = dequeValue.count-1
            }
            if start < 0 {
                clampStart = max(0, dequeValue.count + start)
            }
            
            return Array(dequeValue[clampStart...clampedStop])
        }
        return nil
    }
    
    struct DataEntry {
        let value: Any
        let expiryTimeSinceEpochMs: UInt64
    }
}


