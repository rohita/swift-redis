import Foundation

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

extension Date {
    var msSinceEpoch: UInt64 {
        UInt64(timeIntervalSince1970 * 1000)
    }
}

extension Int {
    init?(_ value: Any) {
        if let stringValue = value as? String {
            self.init(stringValue)
        } else {
            return nil
        }
    }
    
    init?(_ value: String?) {
        if let stringValue = value {
            self.init(stringValue)
        } else {
            return nil
        }
    }
}
