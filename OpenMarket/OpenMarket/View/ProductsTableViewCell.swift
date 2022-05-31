import UIKit

class ProductsTableViewCell: UITableViewCell {
    @IBOutlet private weak var productImageView: UIImageView!
    @IBOutlet private weak var productTitleLabel: UILabel!
    @IBOutlet private weak var productPriceLabel: UILabel!
    @IBOutlet private weak var productStockLabel: UILabel!
}

extension ProductsTableViewCell: ProductCell {
    func setup(
        titleLabel: NSAttributedString,
        priceLabel: NSAttributedString,
        stockLabel: NSAttributedString
    ) {
        self.productTitleLabel.attributedText = titleLabel
        self.productPriceLabel.attributedText = priceLabel
        self.productStockLabel.attributedText = stockLabel
    }
    
    func setup(imageView: UIImage?) {
        self.productImageView.image = imageView
    }
    
    func setup(imageView data: Data) throws {
        try self.productImageView.setImage(from: data)
    }
}
