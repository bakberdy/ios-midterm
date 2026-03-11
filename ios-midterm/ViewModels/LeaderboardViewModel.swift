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
        let toDelete = records      // snapshot current IDs from memory
        records = []                // clear UI immediately – no waiting for network
        guard !toDelete.isEmpty else { return }

        isLoading = true
        let service = apiService
        Publishers.MergeMany(toDelete.map { service.deleteWin(id: $0.id) })
            .collect()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}
