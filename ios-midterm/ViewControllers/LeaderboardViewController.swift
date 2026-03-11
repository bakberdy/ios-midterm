import UIKit
import Combine

final class LeaderboardViewController: UIViewController {

    private let viewModel: LeaderboardViewModel
    private var cancellables = Set<AnyCancellable>()
    private var records: [WinRecord] = []

    private let tableView = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No results yet. Be the first!"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(viewModel: LeaderboardViewModel) {
        self.viewModel = viewModel
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchWins()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Leaderboard"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Clear All",
            style: .plain,
            target: self,
            action: #selector(clearAll)
        )

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.rowHeight = 52
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }

    private func setupBindings() {
        viewModel.$records
            .sink { [weak self] records in
                self?.records = records
                self?.tableView.reloadData()
                self?.emptyLabel.isHidden = !records.isEmpty
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .sink { [weak self] loading in
                loading ? self?.activityIndicator.startAnimating() : self?.activityIndicator.stopAnimating()
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] message in
                self?.showError(message)
            }
            .store(in: &cancellables)
    }

    @objc private func clearAll() {
        viewModel.deleteAllWins()
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension LeaderboardViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let record = records[indexPath.row]
        let seconds = Double(record.timeMs) / 1000.0
        cell.textLabel?.text = "#\(indexPath.row + 1)  \(record.name) - \(String(format: "%.2f", seconds))s"
        cell.textLabel?.font = .monospacedDigitSystemFont(ofSize: 17, weight: .regular)
        return cell
    }
}
