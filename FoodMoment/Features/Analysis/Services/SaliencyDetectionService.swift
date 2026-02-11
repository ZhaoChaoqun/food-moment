import Vision
import UIKit

/// 图像主体检测服务，使用 iOS Vision 框架检测图像中的显著区域
@MainActor
final class SaliencyDetectionService {

    // MARK: - Singleton

    static let shared = SaliencyDetectionService()
    private init() {}

    // MARK: - Configuration

    /// 图像偏移配置参数
    enum OffsetConfig {
        /// 最大偏移比例（相对于屏幕高度）
        static let maxOffsetRatio: CGFloat = 0.25

        /// 开始偏移的阈值（主体 Y 坐标，0-1 归一化）
        static let offsetThreshold: CGFloat = 0.4

        /// 动画响应时间
        static let animationResponse: CGFloat = 0.35

        /// 动画阻尼系数
        static let animationDamping: CGFloat = 0.8
    }

    // MARK: - Public Methods

    /// 检测图像中的主体位置
    /// - Parameter image: 待检测的图像
    /// - Returns: 主体中心的 Y 坐标（0-1 归一化，0 为顶部，1 为底部），检测失败返回 nil
    nonisolated func detectSaliencyCenter(in image: UIImage) async -> CGFloat? {
        guard let cgImage = image.cgImage else { return nil }

        // 在后台线程执行 Vision 请求
        return await Task.detached(priority: .userInitiated) {
            let request = VNGenerateAttentionBasedSaliencyImageRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                print("[SaliencyDetection] Handler error: \(error.localizedDescription)")
                return nil
            }

            // 同步访问结果
            guard let result = request.results?.first as? VNSaliencyImageObservation,
                  let salientObjects = result.salientObjects,
                  !salientObjects.isEmpty else {
                print("[SaliencyDetection] No salient objects detected")
                return nil
            }

            // 找到最大的显著区域
            let primaryObject = salientObjects.max { $0.boundingBox.area < $1.boundingBox.area }

            if let boundingBox = primaryObject?.boundingBox {
                // Vision 坐标系：原点在左下角，Y 轴向上
                // 转换为 UIKit 坐标系：原点在左上角，Y 轴向下
                let centerY = 1 - (boundingBox.midY)
                print("[SaliencyDetection] Detected center Y: \(centerY)")
                return centerY
            }

            return nil
        }.value
    }

    /// 根据主体位置计算图像偏移量
    /// - Parameters:
    ///   - saliencyCenterY: 主体中心 Y 坐标（0-1 归一化，0=顶部，1=底部）
    ///   - screenHeight: 屏幕高度
    /// - Returns: 图像应该偏移的距离（正值表示向下偏移，让底部内容可见）
    func calculateImageOffset(saliencyCenterY: CGFloat?, screenHeight: CGFloat) -> CGFloat {
        guard let centerY = saliencyCenterY else { return 0 }

        // 如果主体在上半部分（Y < 0.4），不需要偏移
        if centerY <= OffsetConfig.offsetThreshold {
            return 0
        }

        // 当食物在底部时（centerY 接近 1.0），需要向下偏移图片容器
        // 这样底部的食物就能显示在屏幕可见区域
        // 线性映射：centerY 0.4-1.0 → offset 0% 到 -25% 的屏幕高度
        // 注意：这里的 offset 应用于图片，负值让图片向上移动，
        // 但因为图片是 fill 模式且被 clipped，实际效果是显示图片的更下方部分
        let factor = (centerY - OffsetConfig.offsetThreshold) / (1 - OffsetConfig.offsetThreshold)
        let offset = -screenHeight * OffsetConfig.maxOffsetRatio * factor

        print("[SaliencyDetection] Calculated offset: \(offset) for centerY: \(centerY)")
        return offset
    }

    /// 根据食物检测结果的 boundingBox 计算主体中心
    /// - Parameter boundingBoxes: 食物检测返回的边界框列表
    /// - Returns: 主要食物的中心 Y 坐标
    func calculateCenterFromBoundingBoxes(_ boundingBoxes: [BoundingBoxDTO]) -> CGFloat? {
        guard !boundingBoxes.isEmpty else { return nil }

        // 如果只有一个食物，直接返回其中心
        if boundingBoxes.count == 1 {
            let box = boundingBoxes[0]
            return box.y + box.h / 2
        }

        // 多个食物时，计算加权中心（按面积加权）
        var totalWeight: CGFloat = 0
        var weightedCenterY: CGFloat = 0

        for box in boundingBoxes {
            let area = box.w * box.h
            let centerY = box.y + box.h / 2
            weightedCenterY += centerY * area
            totalWeight += area
        }

        guard totalWeight > 0 else { return nil }
        return weightedCenterY / totalWeight
    }
}

// MARK: - CGRect Extension

private extension CGRect {
    var area: CGFloat {
        return width * height
    }
}
