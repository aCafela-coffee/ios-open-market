import UIKit

class ProductsCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var productImageView: UIImageView!
    @IBOutlet private weak var productTitleLabel: UILabel!
    @IBOutlet private weak var productPriceLabel: UILabel!
    @IBOutlet private weak var productStockLabel: UILabel!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.systemGray.cgColor
        self.layer.cornerRadius = 10
    }
}

extension ProductsCollectionViewCell: ProductCell {
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
