import UIKit

extension UIImage {

    /// 按最大尺寸等比缩放图片
    ///
    /// 当图片的宽或高超过 `maxDimension` 时，等比缩小至该限制。
    /// 若图片已在限制内则直接返回原图。
    func resized(maxDimension: CGFloat) -> UIImage {
        let ratio = max(size.width, size.height) / maxDimension
        guard ratio > 1 else { return self }

        let newSize = CGSize(
            width: size.width / ratio,
            height: size.height / ratio
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
