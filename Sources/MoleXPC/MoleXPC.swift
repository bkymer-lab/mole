import Foundation

@objc(MoleHelperProtocol)
public protocol MoleHelperProtocol {
    func executeTask(kind: String, reply: @escaping (Bool, String?) -> Void)
}

public let MoleMachServiceName = "com.mole.daemon"
