
class DataStore {
    var data: [String: String] = [:]
    
    func getItem(_ key: String) -> String? {
        data[key]
    }
    
    func setItem(_ key: String, value: String) {
        data[key] = value
    }
}
