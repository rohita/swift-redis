import Foundation
import NIOCore
import NIOPosix

class ClientConnectionHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    let respHeader: RespHandler = RespHandler()
    let commandHandler: Command = Command()
    var dataStore: DataStore
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }
    
    // channel is connected
    func channelActive(context: ChannelHandlerContext) {
        print("[+] New Channel, client address: ", context.channel.remoteAddress?.description ?? "-")
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = unwrapInboundIn(data)
        let readableBytes = buffer.readableBytes
        guard let received = buffer.readString(length: readableBytes) else {
            return
        }
        
        print("Received:\n\(received)")
        let (clientResp, _) = respHeader.parse(from: received.data(using: .utf8)!)
        let serverResp = commandHandler.handle(clientResp, dataStore: self.dataStore)
        let respString = serverResp.encode()
        print("Sending:\n\(respString)")
        let respBuffer = context.channel.allocator.buffer(string: respString)
        context.writeAndFlush(Self.wrapOutboundOut(respBuffer), promise: nil)
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        context.flush()
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: \(error.localizedDescription)")
        context.close(promise: nil)
    }
}

