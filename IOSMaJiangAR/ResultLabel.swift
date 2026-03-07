import UIKit

final class ResultLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        textColor = .systemYellow
        font = .systemFont(ofSize: 24, weight: .bold)
        numberOfLines = 2
        textAlignment = .left
        backgroundColor = UIColor.black.withAlphaComponent(0.35)
        layer.cornerRadius = 10
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        let inset = rect.inset(by: UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12))
        super.drawText(in: inset)
    }
}
