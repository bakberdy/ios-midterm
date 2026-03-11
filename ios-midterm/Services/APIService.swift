import Foundation
import Combine

enum APIConstants {
    static let baseURL = "https://69b13712adac80b427c45fd2.mockapi.io"
}

final class APIService {

    func fetchWins() -> AnyPublisher<[WinRecord], Error> {
        let url = URL(string: "\(APIConstants.baseURL)/wins")!
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [WinRecord].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func saveWin(name: String, timeMs: Int) -> AnyPublisher<WinRecord, Error> {
        let url = URL(string: "\(APIConstants.baseURL)/wins")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(WinPayload(name: name, timeMs: timeMs))
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: WinRecord.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func deleteWin(id: String) -> AnyPublisher<Void, Error> {
        let url = URL(string: "\(APIConstants.baseURL)/wins/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        return URLSession.shared.dataTaskPublisher(for: request)
            .map { _ in () }
            .mapError { $0 as Error }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
