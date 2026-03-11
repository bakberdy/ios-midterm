import Foundation
import Combine

final class LeaderboardViewModel {

    @Published var records: [WinRecord] = []
    @Published var errorMessage: String? = nil
    @Published var isLoading: Bool = false

    let apiService: APIService
    private var cancellables = Set<AnyCancellable>()

    init(apiService: APIService) {
        self.apiService = apiService
    }

    func fetchWins() {
        isLoading = true
        apiService.fetchWins()
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] wins in
                self?.records = Array(wins.sorted { $0.timeMs < $1.timeMs }.prefix(10))
            })
            .store(in: &cancellables)
    }

    func saveWin(name: String, timeMs: Int, completion: (() -> Void)? = nil) {
        isLoading = true
        let service = apiService
        service.saveWin(name: name, timeMs: timeMs)
            .flatMap { _ in service.fetchWins() }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.isLoading = false
                if case .failure(let error) = result {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] wins in
                self?.records = Array(wins.sorted { $0.timeMs < $1.timeMs }.prefix(10))
                completion?()
            })
            .store(in: &cancellables)
    }

    func deleteAllWins() {
        let service = apiService
        isLoading = true
        service.fetchWins()
            .flatMap { records -> AnyPublisher<Void, Error> in
                guard !records.isEmpty else {
                    return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
                return Publishers.MergeMany(records.map { service.deleteWin(id: $0.id) })
                    .collect()
                    .map { _ in () }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] _ in
                self?.records = []
            })
            .store(in: &cancellables)
    }
}
