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
