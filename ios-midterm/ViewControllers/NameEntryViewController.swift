import UIKit

final class NameEntryViewController: UIViewController {

    private let displayTime: String
    private let validate: (String?) -> String?
    private let onSave: (String) -> Void

    private let nameField = UITextField()
    private let errorLabel = UILabel()

    init(displayTime: String,
         validate: @escaping (String?) -> String?,
         onSave: @escaping (String) -> Void) {
        self.displayTime = displayTime
        self.validate = validate
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameField.becomeFirstResponder()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 14
        card.layer.masksToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 270)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "You win!"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center

        let timeLabel = UILabel()
        timeLabel.text = "Time: \(displayTime)s"
        timeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timeLabel.textAlignment = .center
        timeLabel.textColor = .secondaryLabel

        let promptLabel = UILabel()
        promptLabel.text = "Enter your name:"
        promptLabel.font = .systemFont(ofSize: 13, weight: .regular)
        promptLabel.textColor = .secondaryLabel
        promptLabel.textAlignment = .center

        nameField.placeholder = "Your name"
        nameField.borderStyle = .roundedRect
        nameField.autocorrectionType = .no
        nameField.returnKeyType = .done
        nameField.delegate = self

        errorLabel.text = ""
        errorLabel.font = .systemFont(ofSize: 12, weight: .regular)
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.isHidden = true

        let fieldStack = UIStackView(arrangedSubviews: [nameField, errorLabel])
        fieldStack.axis = .vertical
        fieldStack.spacing = 4

        let contentStack = UIStackView(arrangedSubviews: [titleLabel, timeLabel, promptLabel, fieldStack])
        contentStack.axis = .vertical
        contentStack.spacing = 8
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(contentStack)

        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(divider)

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        let verticalDivider = UIView()
        verticalDivider.backgroundColor = .separator
        verticalDivider.translatesAutoresizingMaskIntoConstraints = false

        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [cancelButton, saveButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(buttonRow)
        card.addSubview(verticalDivider)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            divider.topAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: 20),
            divider.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5),
            buttonRow.topAnchor.constraint(equalTo: divider.bottomAnchor),
            buttonRow.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            buttonRow.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            buttonRow.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            buttonRow.heightAnchor.constraint(equalToConstant: 44),
            verticalDivider.centerXAnchor.constraint(equalTo: buttonRow.centerXAnchor),
            verticalDivider.topAnchor.constraint(equalTo: buttonRow.topAnchor),
            verticalDivider.bottomAnchor.constraint(equalTo: buttonRow.bottomAnchor),
            verticalDivider.widthAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    @objc private func saveTapped() {
        let raw = nameField.text
        if let error = validate(raw) {
            errorLabel.text = error
            errorLabel.isHidden = false
            nameField.layer.borderColor = UIColor.systemRed.cgColor
            nameField.layer.borderWidth = 1
            nameField.layer.cornerRadius = 5
            return
        }
        let name = (raw ?? "").trimmingCharacters(in: .whitespaces)
        dismiss(animated: true) { [weak self] in
            self?.onSave(name)
        }
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

extension NameEntryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveTapped()
        return false
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard !errorLabel.isHidden else { return }
        errorLabel.isHidden = true
        textField.layer.borderWidth = 0
    }
}
