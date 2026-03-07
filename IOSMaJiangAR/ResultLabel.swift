import UIKit

final class ResultLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        textColor = .systemYellow
        font = .systemFont(ofSize: 16, weight: .semibold)
        numberOfLines = 3
        textAlignment = .left
        backgroundColor = UIColor.black.withAlphaComponent(0.35)
        layer.cornerRadius = 8
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        let inset = rect.inset(by: UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8))
        super.drawText(in: inset)
    }
}
