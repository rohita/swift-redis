// The Swift Programming Language
// https://docs.swift.org/swift-book

let REDIS_DEFAULT_PORT = 6379

let server = Server(host: "127.0.0.1", port: REDIS_DEFAULT_PORT)
do {
    try server.start()
} catch let error {
    print("Error: \(error.localizedDescription)")
    server.stop()
}
