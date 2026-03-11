import UIKit
import Combine

final class GameViewController: UIViewController {

    private let viewModel = GameViewModel()
    private let leaderboardViewModel: LeaderboardViewModel
    private var cancellables = Set<AnyCancellable>()
    private var numberButtons: [UIButton] = []

    private let timeLabel = UILabel()
    private let nextLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let gridStackView = UIStackView()

    init(leaderboardViewModel: LeaderboardViewModel) {
        self.leaderboardViewModel = leaderboardViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "NumberRush"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Leaderboard",
            style: .plain,
            target: self,
            action: #selector(openLeaderboard)
        )

        timeLabel.font = .monospacedDigitSystemFont(ofSize: 32, weight: .bold)
        timeLabel.textAlignment = .center
        timeLabel.text = "Time: 00.00"

        nextLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        nextLabel.textAlignment = .center
        nextLabel.text = "Next: 1"

        startButton.setTitle("Start", for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 10
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        resetButton.backgroundColor = .systemGray
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.layer.cornerRadius = 10
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)

        for _ in 1...9 {
            let btn = UIButton(type: .system)
            btn.titleLabel?.font = .systemFont(ofSize: 28, weight: .bold)
            btn.backgroundColor = .systemBlue
            btn.setTitleColor(.white, for: .normal)
            btn.layer.cornerRadius = 12
            btn.isEnabled = false
            btn.addTarget(self, action: #selector(numberTapped(_:)), for: .touchUpInside)
            numberButtons.append(btn)
        }

        gridStackView.axis = .vertical
        gridStackView.spacing = 12
        gridStackView.distribution = .fillEqually

        for row in 0..<3 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 12
            rowStack.distribution = .fillEqually
            for col in 0..<3 {
                rowStack.addArrangedSubview(numberButtons[row * 3 + col])
            }
            gridStackView.addArrangedSubview(rowStack)
        }

        let buttonRow = UIStackView(arrangedSubviews: [startButton, resetButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 20
        buttonRow.distribution = .fillEqually

        let mainStack = UIStackView(arrangedSubviews: [timeLabel, nextLabel, buttonRow, gridStackView])
        mainStack.axis = .vertical
        mainStack.spacing = 24
        mainStack.alignment = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            buttonRow.heightAnchor.constraint(equalToConstant: 50),
            gridStackView.heightAnchor.constraint(equalTo: gridStackView.widthAnchor)
        ])
    }

    private func setupBindings() {
        viewModel.$timeString
            .sink { [weak self] time in
                self?.timeLabel.text = "Time: \(time)"
            }
            .store(in: &cancellables)

        viewModel.$nextTarget
            .sink { [weak self] target in
                self?.nextLabel.text = "Next: \(target > 9 ? "Done!" : "\(target)")"
            }
            .store(in: &cancellables)

        viewModel.$isGameActive
            .sink { [weak self] active in
                self?.numberButtons.forEach { $0.isEnabled = active }
                self?.startButton.isEnabled = !active
            }
            .store(in: &cancellables)

        viewModel.$shuffledNumbers
            .sink { [weak self] numbers in
                guard let self else { return }
                for (index, btn) in self.numberButtons.enumerated() {
                    let num = numbers[index]
                    btn.tag = num
                    btn.setTitle("\(num)", for: .normal)
                }
            }
            .store(in: &cancellables)

        viewModel.$winEvent
            .compactMap { $0 }
            .sink { [weak self] event in
                self?.showWinAlert(event: event)
            }
            .store(in: &cancellables)
    }

    @objc private func startTapped() {
        viewModel.startGame()
    }

    @objc private func resetTapped() {
        viewModel.resetGame()
    }

    @objc private func numberTapped(_ sender: UIButton) {
        viewModel.handleTap(number: sender.tag)
    }

    @objc private func openLeaderboard() {
        let vc = LeaderboardViewController(viewModel: leaderboardViewModel)
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showWinAlert(event: (timeMs: Int, displayTime: String)) {
        let vc = NameEntryViewController(
            displayTime: event.displayTime,
            validate: { [weak self] name in self?.viewModel.validateName(name) },
            onSave: { [weak self] name in
                guard let self else { return }
                self.leaderboardViewModel.saveWin(name: name, timeMs: event.timeMs) { [weak self] in
                    guard let self else { return }
                    let leaderboard = LeaderboardViewController(viewModel: self.leaderboardViewModel)
                    self.navigationController?.pushViewController(leaderboard, animated: true)
                }
            }
        )
        present(vc, animated: true)
    }
}
