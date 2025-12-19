import Foundation
import CryptoKit

extension String {
    /// SHA256ハッシュ値を計算して16進数文字列として返す
    func sha256Hash() -> String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
