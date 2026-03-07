import UIKit

final class MahjongHandView: UIView {
    var onDeleteTile: ((Int) -> Void)?

    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private var tiles: [MahjongTile] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(tiles: [MahjongTile]) {
        self.tiles = tiles
        reloadTiles()
    }

    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.35)
        layer.cornerRadius = 12
        clipsToBounds = true

        scrollView.showsHorizontalScrollIndicator = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center

        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    private func reloadTiles() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        for (index, tile) in tiles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(tile.displayName, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.7)
            button.layer.cornerRadius = 8
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
            button.tag = index
            button.addTarget(self, action: #selector(handleDelete(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }
    }

    @objc private func handleDelete(_ sender: UIButton) {
        onDeleteTile?(sender.tag)
    }
}
