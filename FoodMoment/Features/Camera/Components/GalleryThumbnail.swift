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
            thumbnailContent
        }
        .onChange(of: selectedItem) { _, newItem in
            loadImage(from: newItem)
        }
        .accessibilityLabel("Photo Library")
    }

    // MARK: - Thumbnail Content

    private var thumbnailContent: some View {
        ZStack {
            backgroundRectangle

            if let thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                placeholderIcon
            }

            borderOverlay
        }
    }

    // MARK: - Background Rectangle

    private var backgroundRectangle: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.white.opacity(0.15))
            .frame(width: size, height: size)
    }

    // MARK: - Placeholder Icon

    private var placeholderIcon: some View {
        Image(systemName: "photo.on.rectangle")
            .font(.system(size: 18))
            .foregroundColor(.white)
    }

    // MARK: - Border Overlay

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(Color.white.opacity(0.2), lineWidth: borderWidth)
            .frame(width: size, height: size)
    }

    // MARK: - Private Methods

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                thumbnailImage = image
                selectedImage = image
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
