import Foundation
import Combine

final class GameViewModel {

    @Published var timeString: String = "00.00"
    @Published var nextTarget: Int = 1
    @Published var isGameActive: Bool = false
    @Published var winEvent: (timeMs: Int, displayTime: String)? = nil
    @Published var shuffledNumbers: [Int] = Array(1...9)

    private var elapsedCentiseconds: Int = 0
    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    func startGame() {
        elapsedCentiseconds = 0
        nextTarget = 1
        winEvent = nil
        shuffledNumbers = Array(1...9).shuffled()
        isGameActive = true

        timerCancellable = Timer.publish(every: 0.01, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func resetGame() {
        timerCancellable?.cancel()
        timerCancellable = nil
        elapsedCentiseconds = 0
        nextTarget = 1
        timeString = "00.00"
        isGameActive = false
        winEvent = nil
        shuffledNumbers = Array(1...9)
    }

    func handleTap(number: Int) {
        guard isGameActive else { return }
        guard number == nextTarget else { return }
        nextTarget += 1
        if nextTarget > 9 {
            timerCancellable?.cancel()
            timerCancellable = nil
            isGameActive = false
            winEvent = (timeMs: elapsedCentiseconds * 10, displayTime: formatTime(elapsedCentiseconds))
        }
    }

    func validateName(_ raw: String?) -> String? {
        let trimmed = (raw ?? "").trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "Name cannot be empty"
        }
        if trimmed.count < 2 {
            return "Name must be at least 2 characters"
        }
        return nil
    }

    private func tick() {
        elapsedCentiseconds += 1
        timeString = formatTime(elapsedCentiseconds)
    }

    private func formatTime(_ cs: Int) -> String {
        let seconds = cs / 100
        let centiseconds = cs % 100
        return String(format: "%02d.%02d", seconds, centiseconds)
    }
}
