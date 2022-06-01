import UIKit

class ProductRegistrationViewController: UIViewController, UINavigationControllerDelegate {
    static let storyboardName = "ProductRegistration"
    private let maximumDescriptionsLimit = 1000
    private let minimumDescriptionsLimit = 10
    private let maximumNameLimit = 100
    private let minimumNameLimit = 3
    private let loadingActivityIndicator = UIActivityIndicatorView()
    private let imagePickerController = UIImagePickerController()
    private var images = [UIImage]()
    private var isModifying: Bool?
    private var productInformation: Product?
    private var networkTask: NetworkTask?
    private var jsonParser: JSONParser?
    private var completionHandler: (() -> Void)?
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var verticalStackView: UIStackView!
    @IBOutlet private weak var imagesCollectionView: UICollectionView!
    @IBOutlet private weak var productNameTextField: UITextField!
    @IBOutlet private weak var productPriceTextField: UITextField!
    @IBOutlet private weak var discountedPriceTextField: UITextField!
    @IBOutlet private weak var stockTextField: UITextField!
    @IBOutlet private weak var descriptionTextView: UITextView!
    @IBOutlet private weak var currencySegmentedControl: UISegmentedControl!
    @IBOutlet private weak var productNameCautionLabel: UILabel!
    @IBOutlet private weak var productPriceCautionLabel: UILabel!
    @IBOutlet private weak var discountedPriceCautionLabel: UILabel!
    @IBOutlet private weak var descriptionCautionLabel: UILabel!
    
    convenience init?(
        coder: NSCoder,
        isModifying: Bool,
        networkTask: NetworkTask,
        jsonParser: JSONParser,
        completionHandler: (() -> Void)?
    ) {
        self.init(coder: coder)
        self.isModifying = isModifying
        self.networkTask = networkTask
        self.jsonParser = jsonParser
        self.completionHandler = completionHandler
    }
    
    convenience init?(
        coder: NSCoder,
        isModifying: Bool,
        productInformation: Product,
        networkTask: NetworkTask,
        jsonParser: JSONParser,
        completionHandler: (() -> Void)?
    ) {
        self.init(coder: coder)
        self.isModifying = isModifying
        self.networkTask = networkTask
        self.jsonParser = jsonParser
        self.completionHandler = completionHandler
        self.productInformation = productInformation
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagesCollectionView.dataSource = self
        setupDelegate()
        setupImagePicker()
        setupNavigationBar()
        setupTextView()
        hideAllCautionLabel()
        loadProductInformation()
        addKeyboardObserver()
    }
    
    @objc private func registerProduct() {
        startActivityIndicator()
        DispatchQueue.global().async {
            var writtenSalesInformation: Result<NetworkTask.SalesInformation, ProductRegistrationError>!
            DispatchQueue.main.sync {
                writtenSalesInformation = self.makeSalesInformation(
                    secret: NetworkTask.secret,
                    maximumDescriptionsLimit: 1000,
                    minimumDescriptionsLimit: 10,
                    maximumNameLimit: 100,
                    minimumNameLimit: 3
                )
            }

            let salesInformation: NetworkTask.SalesInformation
            switch writtenSalesInformation! {
            case .success(let result):
                salesInformation = result
            case .failure(let error):
                DispatchQueue.main.async {
                    self.loadingActivityIndicator.removeFromSuperview()
                }
                self.showAlert(title: error.errorDescription, message: nil)
                return
            }
            
            var imageDatas = [String: Data]()
            for (count, image) in self.images.enumerated() {
                let fileName = "\(count).jpeg"
                let imageData = self.convertJPEG(
                    from: image,
                    finalByte: 300 * 1000,
                    compressionQuality: 0.8
                )
                imageDatas[fileName] = imageData
            }
            
            self.networkTask?.requestProductRegistration(
                identifier: NetworkTask.identifier,
                salesInformation: salesInformation,
                images: imageDatas
            ) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: self.completionHandler)
                    }
                case .failure(let error):
                        DispatchQueue.main.async {
                            self.loadingActivityIndicator.removeFromSuperview()
                        }
                    self.showAlert(title: "등록 실패", message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func modifyProduct() {
        startActivityIndicator()
        DispatchQueue.global().async {
            let writtenSalesInformation = self.modifiySalesInformation(
                secret: NetworkTask.secret,
                maximumDescriptionsLimit: 1000,
                minimumDescriptionsLimit: 10,
                maximumNameLimit: 100,
                minimumNameLimit: 3
            )
            let modificationInformation: NetworkTask.ModificationInformation
            switch writtenSalesInformation {
            case .success(let result):
                modificationInformation = result
            case .failure(let error):
                self.showAlert(title: error.errorDescription, message: nil)
                return
            }
            
            guard let productId = self.productInformation?.id else { return }
            self.networkTask?.requestProductModification(
                identifier: NetworkTask.identifier,
                productId: productId,
                information: modificationInformation
            ) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.dismiss(animated: true, completion: self.completionHandler)
                    }
                case .failure(let error):
                    self.showAlert(title: "수정 실패", message: error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func dismissProductRegistration() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func presentImagePicker() {
        present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc private func keyboardWillShow(_ sender: Notification) {
        if let keyboardFrame = sender.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
            as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            scrollView.contentInset.bottom = keyboardHeight
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        }
    }
    
    @objc private func keyboardWillHide(_ sender: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(dismissProductRegistration)
        )
        if isModifying == .some(true) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(modifyProduct)
            )
            navigationItem.title = "상품수정"
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(registerProduct)
            )
            navigationItem.title = "상품등록"
        }
    }
    
    private func setupDelegate() {
        productNameTextField.delegate = self
        productPriceTextField.delegate = self
        discountedPriceTextField.delegate = self
        stockTextField.delegate = self
    }
    
    private func setupImagePicker() {
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
    }
    
    private func setupTextView() {
        descriptionTextView.delegate = self
        descriptionTextView.text = "상품설명"
        descriptionTextView.textColor = .placeholderText
        descriptionTextView.layer.borderWidth = 0.5
        descriptionTextView.layer.cornerRadius = 5
        descriptionTextView.layer.borderColor = UIColor.separator.cgColor
    }
    
    private func startActivityIndicator() {
        view.addSubview(loadingActivityIndicator)
        loadingActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingActivityIndicator.centerYAnchor.constraint(
            equalTo: view.centerYAnchor
        ).isActive = true
        loadingActivityIndicator.centerXAnchor.constraint(
            equalTo: view.centerXAnchor
        ).isActive = true
        loadingActivityIndicator.startAnimating()
    }
    
    private func addKeyboardObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func hideAllCautionLabel() {
        productNameCautionLabel.isHidden = true
        productPriceCautionLabel.isHidden = true
        discountedPriceCautionLabel.isHidden = true
        descriptionCautionLabel.isHidden = true
    }
    
    private func showCaution(textField: UITextField, cautionLabel: UILabel, message: String?) {
        cautionLabel.text = message
        cautionLabel.isHidden = false
        textField.layer.borderColor = UIColor.systemRed.cgColor
        textField.layer.cornerRadius = 5
        textField.layer.borderWidth = 0.5
    }
    
    private func showCaution(textView: UITextView, cautionLabel: UILabel, message: String?) {
        cautionLabel.text = message
        cautionLabel.isHidden = false
        textView.layer.borderColor = UIColor.systemRed.cgColor
        textView.layer.borderWidth = 0.5
    }
    
    private func hideCaution(textField: UITextField, cautionLabel: UILabel) {
        textField.layer.borderWidth = 0.0
        cautionLabel.isHidden = true
    }
    
    private func hideCaution(textView: UITextView, cautionLabel: UILabel) {
        cautionLabel.isHidden = true
        textView.layer.borderColor = UIColor.separator.cgColor
    }
    
    private func loadProductInformation() {
        guard let productInformation = productInformation else { return }
        productNameTextField.text = productInformation.name
        productPriceTextField.text = productInformation.price.description
        discountedPriceTextField.text = productInformation.discountedPrice.description
        stockTextField.text = productInformation.stock.description
        descriptionTextView.text = productInformation.description
        descriptionTextView.textColor = .label
        if productInformation.currency == .krw {
            currencySegmentedControl.selectedSegmentIndex = 0
        } else if productInformation.currency == .usd {
            currencySegmentedControl.selectedSegmentIndex = 1
        }
        productInformation.images?.forEach { image in
            guard let url = URL(string: image.url),
                  let imageData = try? Data(contentsOf: url),
                  let downloadedImage = UIImage(data: imageData) else { return }
            images.append(downloadedImage)
        }
    }
    
    private func makeSalesInformation(
        secret: String,
        maximumDescriptionsLimit: Int?,
        minimumDescriptionsLimit: Int?,
        maximumNameLimit: Int?,
        minimumNameLimit: Int?
    ) -> Result<NetworkTask.SalesInformation, ProductRegistrationError> {
        let selectedSegmentIndex = currencySegmentedControl.selectedSegmentIndex
        let selectedSegmentTitle = currencySegmentedControl.titleForSegment(
            at: selectedSegmentIndex
        ) ?? ""
        let result = inspectInput(
            name: productNameTextField.text,
            price: productPriceTextField.text,
            discountedPrice: discountedPriceTextField.text,
            currencyTitle: selectedSegmentTitle,
            stock: stockTextField.text,
            descriptions: descriptionTextView.text
        )
        switch result {
        case .success(let productRegistration):
            let product = NetworkTask.SalesInformation(
                name: productRegistration.name,
                descriptions: productRegistration.descriptions,
                price: productRegistration.price,
                currency: productRegistration.currency,
                discountedPrice: productRegistration.discountedPrice,
                stock: productRegistration.stock,
                secret: secret)
            return .success(product)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    private func modifiySalesInformation(
        secret: String,
        maximumDescriptionsLimit: Int?,
        minimumDescriptionsLimit: Int?,
        maximumNameLimit: Int?,
        minimumNameLimit: Int?
    ) -> Result<NetworkTask.ModificationInformation, ProductRegistrationError> {
        let selectedSegmentIndex = currencySegmentedControl.selectedSegmentIndex
        let selectedSegmentTitle = currencySegmentedControl.titleForSegment(
            at: selectedSegmentIndex
        ) ?? ""
        let result = inspectInput(
            name: productNameTextField.text,
            price: productPriceTextField.text,
            discountedPrice: discountedPriceTextField.text,
            currencyTitle: selectedSegmentTitle,
            stock: stockTextField.text,
            descriptions: descriptionTextView.text
        )
        switch result {
        case .success(let productRegistration):
            let product = NetworkTask.ModificationInformation(
                name: productRegistration.name,
                descriptions: productRegistration.descriptions,
                thumbnailId: nil,
                price: productRegistration.price,
                currency: productRegistration.currency,
                discountedPrice: productRegistration.discountedPrice,
                stock: productRegistration.stock,
                secret: secret)
            return .success(product)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    private func textInputDidChange(_ sender: Any, textLength: Int) {
        if let textField = sender as? UITextField {
            if productNameTextField.isFirstResponder {
                if textLength < minimumNameLimit || textLength > maximumNameLimit {
                    showCaution(
                        textField: textField,
                        cautionLabel: productNameCautionLabel,
                        message: "글자를 \(minimumNameLimit)~\(maximumNameLimit)자로 입력해주세요"
                    )
                } else {
                    hideCaution(textField: textField, cautionLabel: productNameCautionLabel)
                }
            }
            if productPriceTextField.isFirstResponder {
                if textLength == 0 {
                    showCaution(
                        textField: textField,
                        cautionLabel: productPriceCautionLabel,
                        message: "상품가격을 입력해주세요"
                    )
                } else {
                    hideCaution(textField: textField, cautionLabel: productPriceCautionLabel)
                }
                if let price = Decimal(string: textField.text ?? ""),
                   let discountedPrice = Decimal(string: discountedPriceTextField.text ?? ""),
                   let error = inspectMaximumDiscountedPrice(
                    price: price,
                    discountedPrice: discountedPrice
                   ) {
                    showCaution(
                        textField: discountedPriceTextField,
                        cautionLabel: discountedPriceCautionLabel,
                        message: error.errorDescription
                    )
                } else {
                    hideCaution(
                        textField: discountedPriceTextField,
                        cautionLabel: discountedPriceCautionLabel
                    )
                }
            }
            if discountedPriceTextField.isFirstResponder {
                if let price = Decimal(string: productPriceTextField.text ?? ""),
                   let discountedPrice = Decimal(string: textField.text ?? ""),
                   let error = inspectMaximumDiscountedPrice(
                    price: price,
                    discountedPrice: discountedPrice
                   ) {
                    showCaution(
                        textField: textField,
                        cautionLabel: discountedPriceCautionLabel,
                        message: error.errorDescription
                    )
                } else {
                    hideCaution(textField: textField, cautionLabel: discountedPriceCautionLabel)
                }
            }
        } else if let textView = sender as? UITextView {
            if descriptionTextView.isFirstResponder {
                if textLength < minimumDescriptionsLimit || textLength > maximumDescriptionsLimit {
                    showCaution(
                        textView: textView,
                        cautionLabel: descriptionCautionLabel,
                        message: "글자를 \(minimumDescriptionsLimit)~\(maximumDescriptionsLimit)자로 입력해주세요"
                    )
                } else {
                    hideCaution(textView: textView, cautionLabel: descriptionCautionLabel)
                }
            }
        }
    }
    
    private func inspectFilledInput(
        price: Decimal,
        discountedPrice: Decimal?,
        nameCount: Int,
        descriptionsCount: Int,
        maximumDescriptionsLimit: Int?,
        minimumDescriptionsLimit: Int?,
        maximumNameLimit: Int?,
        minimumNameLimit: Int?
    ) -> ProductRegistrationError? {
        if let error = inspectMaximumDiscountedPrice(
            price: price,
            discountedPrice: discountedPrice
        ) {
            return error
        }
        if let error = inspectMinimumName(count: nameCount, limit: minimumNameLimit) {
            return error
        }
        if let error = inspectMaximumName(count: nameCount, limit: maximumNameLimit) {
            return error
        }
        if let error = inspectMinimumDescriptions(
            count: descriptionsCount,
            limit: minimumDescriptionsLimit
        ) {
            return error
        }
        if let error = inspectMaximumDescriptions(
            count: descriptionsCount,
            limit: maximumDescriptionsLimit
        ) {
            return error
        }
        return nil
    }
    
    private func inspectInput(
        name: String?,
        price: String?,
        discountedPrice: String?,
        currencyTitle: String,
        stock: String?,
        descriptions: String?
    ) -> Result<ProductRegistration, ProductRegistrationError> {
        let discountedPrice = Decimal(string: discountedPrice ?? "")
        let stock = UInt(stock ?? "")
        
        guard let name = name, name.isEmpty == false else {
            return .failure(.emptyName)
        }
        guard let price = Decimal(string: price ?? "") else {
            return .failure(.emptyPrice)
        }
        guard let currency = Currency(rawValue: currencyTitle) else {
            return .failure(.emptyCurrency)
        }
        guard let descriptions = descriptions, descriptions != "상품설명" else {
            return .failure(.emptyDiscription)
        }
        guard images.isEmpty == false else {
            return .failure(.emptyImage)
        }
        
        if let error = inspectFilledInput(
            price: price,
            discountedPrice: discountedPrice,
            nameCount: name.count,
            descriptionsCount: descriptions.count,
            maximumDescriptionsLimit: maximumDescriptionsLimit,
            minimumDescriptionsLimit: minimumDescriptionsLimit,
            maximumNameLimit: maximumNameLimit,
            minimumNameLimit: minimumNameLimit
        ) {
            return .failure(error)
        }
        let result = ProductRegistration(
            name: name,
            price: price,
            discountedPrice: discountedPrice,
            currency: currency,
            stock: stock,
            descriptions: descriptions
        )
        return .success(result)
    }
    
    private func inspectMaximumDiscountedPrice(
        price: Decimal,
        discountedPrice: Decimal?
    ) -> ProductRegistrationError? {
        if let discountedPrice = discountedPrice, discountedPrice > price {
            return .maximumDiscountedPrice(price)
        }
        return nil
    }
    
    private func inspectMaximumDescriptions(
        count: Int,
        limit: Int?
    ) -> ProductRegistrationError? {
        if let maximumDescriptionsLimit = limit,
           count > maximumDescriptionsLimit {
            return .maximumCharacterLimit(.description, maximumDescriptionsLimit)
        }
        return nil
    }
    
    private func inspectMinimumDescriptions(
        count: Int,
        limit: Int?
    ) -> ProductRegistrationError? {
        if let minimumDescriptionsLimit = limit,
           count < minimumDescriptionsLimit {
            return .minimumCharacterLimit(.description, minimumDescriptionsLimit)
        }
        return nil
    }
    
    private func inspectMaximumName(
        count: Int,
        limit: Int?
    ) -> ProductRegistrationError? {
        if let maximumNameLimit = limit,
           count > maximumNameLimit {
            return .maximumCharacterLimit(.name, maximumNameLimit)
        }
        return nil
    }
    
    private func inspectMinimumName(
        count: Int,
        limit: Int?
    ) -> ProductRegistrationError? {
        if let minimumNameLimit = limit,
           count < minimumNameLimit {
            return .minimumCharacterLimit(.name, minimumNameLimit)
        }
        return nil
    }
    
    private func makeImageView(with image: UIImage, frame: CGRect) -> UIImageView {
        let imageView = UIImageView(frame: frame)
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        return imageView
    }
    
    private func makeButton(systemName: String) -> UIButton {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: systemName)
        button.setTitle(nil, for: .normal)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(presentImagePicker), for: .touchUpInside)
        button.backgroundColor = .opaqueSeparator
        return button
    }
    
    private func convertJPEG(
        from image: UIImage,
        finalByte: Int,
        compressionQuality: CGFloat
    ) -> Data? {
        var originalImage = image
        var imageData = image.jpegData(compressionQuality: compressionQuality)
        while let bytes = imageData?.count, bytes > finalByte {
            autoreleasepool {
                let multiplier: CGFloat = 0.8
                originalImage = originalImage.resize(multiplier: multiplier)
                imageData = originalImage.jpegData(compressionQuality: compressionQuality)
            }
        }
        return imageData
    }
    
    @IBAction private func tapBackground(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
}

extension ProductRegistrationViewController {
    private enum Section: Int {
        case imagesSection
        case buttonSection
    }
    
    private struct ProductRegistration {
        let name: String
        let price: Decimal
        let discountedPrice: Decimal?
        let currency: Currency
        let stock: UInt?
        let descriptions: String
    }
}

extension ProductRegistrationViewController: UIImagePickerControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard picker.isBeingDismissed == false,
              var newImage = info[.originalImage] as? UIImage else {
                  picker.dismiss(animated: true, completion: nil)
                  return
              }
        let isSquare = newImage.size.width == newImage.size.height
        if isSquare == false {
            if let squareImage = newImage.cropSquare() {
                newImage = squareImage
            }
        }
        images.append(newImage)
        imagesCollectionView.reloadData()
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ProductRegistrationViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if images.count < 5, isModifying == false {
            return 2
        }
        return 1
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        let section = Section(rawValue: section)
        switch section {
        case .imagesSection:
            return images.count
        case .buttonSection:
            return 1
        case .none:
            return 0
        }
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: UICollectionViewCell.identifier,
            for: indexPath
        )
        cell.contentView.subviews.forEach { view in
            view.removeFromSuperview()
        }
        let section = Section(rawValue: indexPath.section)
        switch section {
        case .imagesSection:
            let image = images[indexPath.item]
            let imageView = makeImageView(with: image, frame: cell.contentView.frame)
            cell.contentView.addSubview(imageView)
        case .buttonSection:
            let button = makeButton(systemName: "plus")
            cell.contentView.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            let constraints = [
                button.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
                button.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor),
                button.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor)
            ]
            NSLayoutConstraint.activate(constraints)
        case .none: break
        }
        return cell
    }
}

extension ProductRegistrationViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        let textViewIsEmpty = textView.textColor == .placeholderText
        if textViewIsEmpty {
            textView.text = nil
            textView.textColor = .label
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let count = textView.text?.count {
            let textLength = count - range.length + text.count
            textInputDidChange(textView, textLength: textLength)
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "상품설명"
            textView.textColor = .placeholderText
        }
    }
}

extension ProductRegistrationViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == productNameTextField {
            productPriceTextField.becomeFirstResponder()
        }
        return false
    }
    
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if productPriceTextField.isFirstResponder ||
            discountedPriceTextField.isFirstResponder ||
            stockTextField.isFirstResponder {
            if string.isEmpty {
                return true
            }
            let numberCharacterSet = CharacterSet.decimalDigits
            let inputCharacterSet = CharacterSet(charactersIn: string)
            let isValid = numberCharacterSet.isSuperset(of: inputCharacterSet)
            return isValid
        }
        if let count = textField.text?.count {
            let textLength = count - range.length + string.count
            textInputDidChange(textField, textLength: textLength)
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textInputDidChange(textField, textLength: 0)
        return true
    }
}
