import UIKit

protocol ProductCell {
    func setup(
        titleLabel: NSAttributedString,
        priceLabel: NSAttributedString,
        stockLabel: NSAttributedString
    )
    func setup(imageView: UIImage?)
    func setup(imageView: Data) throws
}
