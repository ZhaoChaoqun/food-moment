import SwiftUI
import PhotosUI
import UIKit

// MARK: - GalleryThumbnail

/// Gallery thumbnail button that opens the system photo picker.
/// Displays a rounded rectangle with a photo icon and white border.
struct GalleryThumbnail: View {

    // MARK: - Properties

    @Binding var selectedImage: UIImage?

    // MARK: - State

    @State private var selectedItem: PhotosPickerItem?
    @State private var thumbnailImage: UIImage?

    // MARK: - Constants

    private let size: CGFloat = 56
    private let cornerRadius: CGFloat = 16
    private let borderWidth: CGFloat = 2

    // MARK: - Body

    var body: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images
        ) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: size, height: size)

                if let thumbnailImage {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                } else {
                    Image(systemName: "photo.on.rectangle")
                        .font(.Jakarta.regular(18))
                        .foregroundColor(.white)
                }

                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.2), lineWidth: borderWidth)
                    .frame(width: size, height: size)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            loadImage(from: newItem)
        }
        .accessibilityLabel("照片库")
    }

    // MARK: - Private Methods

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task { @MainActor in
            if let data = try? await item.loadTransferable(type: Data.self),
               let fullImage = UIImage(data: data) {
                let thumbSize = CGSize(width: 200, height: 200)
                let thumb = await fullImage.byPreparingThumbnail(ofSize: thumbSize) ?? fullImage
                thumbnailImage = thumb
                selectedImage = fullImage
            }
            selectedItem = nil
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black
            .ignoresSafeArea()

        GalleryThumbnail(selectedImage: .constant(nil))
    }
}
