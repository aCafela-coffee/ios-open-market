//
//  UIImageView+extension.swift
//  OpenMarket
//
//  Created by YunYoungseo on 2022/05/31.
//

import UIKit

extension UIImageView {
    func setImage(from data: Data) throws {
        let maximumImageSize = frame.size
        let screenScale = UIScreen.main.scale
        guard let downsampledImage = downsample(imageAt: data, to: maximumImageSize, scale: screenScale) else {
            throw ImageSourceError.decodeFail
        }
        image = downsampledImage
    }
    
    private func downsample(imageAt imageData: Data, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
        let imageSourceOption = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, imageSourceOption) else {
            return nil
        }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions =
        [kCGImageSourceCreateThumbnailFromImageAlways: true,
                 kCGImageSourceShouldCacheImmediately: true,
           kCGImageSourceCreateThumbnailWithTransform: true,
                  kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        return UIImage(cgImage: downsampledImage)
    }
}
