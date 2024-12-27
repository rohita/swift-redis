import Testing
import Collections
import Foundation
@testable import SwiftRedis


struct DataStoreTests {
    let key = "hello"
    let value1 = "world"
    let value2 = "swift"
    
    @Test func hasKeyThenRemove() {
        let db = DataStore()
        db.setItem(key, value: value1)
        #expect(db.hasKey(key) == true)
        db.remove(key)
        #expect(db.hasKey(key) == false)
    }
    
    @Test func expireOnRead() {
        let db = DataStore()
        db.setItem(key, value: value1, expiryTimeMs: 10)
        sleep(1)
        let result = db.getItem(key)
        #expect(result == nil)
        #expect(db.hasKey(key) == false)
    }
    
    @Test func incrementDecrement() {
        let db = DataStore()
        let result1 = db.incr(key)
        let result2 = db.incr(key)
        let result3 = db.decr(key)
        let result4 = db.decr(key)
        #expect(result1! == "1")
        #expect(result2! == "2")
        #expect(result3! == "1")
        #expect(result4! == "0")
    }
    
    @Test func incrementDecrementExisting() {
        let db = DataStore()
        db.setItem(key, value: "19")
        let result1 = db.incr(key)
        let result2 = db.incr(key)
        let result3 = db.decr(key)
        let result4 = db.decr(key)
        #expect(result1! == "20")
        #expect(result2! == "21")
        #expect(result3! == "20")
        #expect(result4! == "19")
    }
    
    @Test func incrementDecrementString() {
        let db = DataStore()
        db.setItem(key, value: value1)
        let result1 = db.incr(key)
        let result2 = db.decr(key)
        #expect(result1 == nil)
        #expect(result2 == nil)
    }
    
    @Test func prependToString() {
        let db = DataStore()
        db.setItem(key, value: value1)
        let result = db.prepend(key, value: value2)
        let value = db.getItem(key)
        let range = db.lrange(key, start: 0, stop: 1)
        #expect(result == nil)
        #expect(value == value1)
        #expect(range == nil)
    }
    
    @Test func prepend() {
        let db = DataStore()
        let result1 = db.prepend(key, value: value1)
        let result2 = db.prepend(key, value: value2)
        let value = db.getItem(key)
        let data = db.getRawData(key)
        #expect(result1 == 1)
        #expect(result2 == 2)
        #expect(value == nil)
        #expect(data?.value as? Deque<String> == [value2, value1])
        #expect(data?.expiryTimeSinceEpochMs == 0)
        
        #expect(db.lrange(key, start: 0, stop: 0) == [value2])
        #expect(db.lrange(key, start: 0, stop: 1) == [value2, value1])
        #expect(db.lrange(key, start: 0, stop: 2) == [value2, value1])
        #expect(db.lrange(key, start: 1, stop: 20) == [value1])
        #expect(db.lrange(key, start: -1, stop: 20) == [value1])
        #expect(db.lrange(key, start: 20, stop: 200) == [])
    }
    
    @Test func appendToString() {
        let db = DataStore()
        db.setItem(key, value: value1)
        let result = db.append(key, value: value2)
        let value = db.getItem(key)
        #expect(result == nil)
        #expect(value == value1)
    }
    
    @Test func append() {
        let db = DataStore()
        let result1 = db.append(key, value: value1)
        let result2 = db.append(key, value: value2)
        let value = db.getItem(key)
        let data = db.getRawData(key)
        #expect(result1 == 1)
        #expect(result2 == 2)
        #expect(value == nil)
        #expect(data?.value as? Deque<String> == [value1, value2])
        #expect(data?.expiryTimeSinceEpochMs == 0)
    }
    
    @Test(arguments: [
        (0, 0, ["one"]),
        (-3, 2, ["one", "two", "three"]),
        (-100, 100, ["one", "two", "three"]),
        (5, 10, []),
    ])
    func lrange(start: Int, stop: Int, expected: [String] ) {
        let db = DataStore()
        let _ = db.append(key, value: "one")
        let _ = db.append(key, value: "two")
        let _ = db.append(key, value: "three")
        let result = db.lrange(key, start: start, stop: stop)
        #expect(result == expected)
    }
}

