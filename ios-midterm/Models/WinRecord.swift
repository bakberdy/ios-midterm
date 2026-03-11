import Foundation

struct WinRecord: Codable {
    let id: String
    let name: String
    let timeMs: Int
    let createdAt: String?
}

struct WinPayload: Codable {
    let name: String
    let timeMs: Int
}
