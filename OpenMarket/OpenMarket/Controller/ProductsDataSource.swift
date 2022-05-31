import UIKit

class ProductsDataSource: NSObject {
    private var products = [Product]()
    private var networkTask: NetworkTask?
    
    convenience init(networkTask: NetworkTask) {
        self.init()
        self.networkTask = networkTask
    }
    
    func append(contentsOf products: [Product]) {
        self.products.append(contentsOf: products)
    }
    
    func isLastIndex(at index: Int) -> Bool {
        return index == products.count - 1
    }
    
    func removeAllProducts() {
        products = [Product]()
    }
    
    func productId(at index: Int) -> Int? {
        return products[safe: index]?.id
    }
    
    func vendorId(at index: Int) -> Int? {
        return products[safe: index]?.vendorId
    }
    
    private func setupCellImage(
        for cell: ProductCell,
        from url: URL,
        indexPath: IndexPath,
        productView: ProductView
    ) {
        cell.setup(imageView: nil)
        networkTask?.downloadImage(from: url) { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    guard indexPath == productView.indexPath(for: cell) else { return }
                    do {
                        try cell.setup(imageView: data)
                    } catch {
                        let alternativeImage = UIImage(systemName: "xmark.app")
                        cell.setup(imageView: alternativeImage)
                    }
                }
            case .failure:
                let image = UIImage(systemName: "xmark.app")
                DispatchQueue.main.async {
                    guard indexPath == productView.indexPath(for: cell) else { return }
                    cell.setup(imageView: image)
                }
            }
        }
    }
}

extension ProductsDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let product = products[indexPath.row]
        let reuseIdentifier = ProductsTableViewCell.identifier
        let cell = tableView.dequeueReusableCell(
            withIdentifier: reuseIdentifier,
            for: indexPath
        )
        guard let cell = cell as? ProductsTableViewCell,
              let url = URL(string: product.thumbnail) else {
                  return cell
              }
        cell.setup(
            titleLabel: product.attributedTitle,
            priceLabel: product.attributedPrice,
            stockLabel: product.attributedStock
        )
        setupCellImage(for: cell, from: url, indexPath: indexPath, productView: tableView)
        return cell
    }
}

extension ProductsDataSource: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        return products.count
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let product = products[indexPath.item]
        let reuseIdentifier = ProductsCollectionViewCell.identifier
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        )
        guard let cell = cell as? ProductsCollectionViewCell,
              let url = URL(string: product.thumbnail) else {
                  return cell
              }
        cell.setup(
            titleLabel: product.attributedTitle,
            priceLabel: product.attributedPrice,
            stockLabel: product.attributedStock
        )
        setupCellImage(for: cell, from: url, indexPath: indexPath, productView: collectionView)
        return cell
    }
}
