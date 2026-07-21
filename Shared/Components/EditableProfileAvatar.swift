#if canImport(PhotosUI) && canImport(UIKit)
import SwiftUI
import PhotosUI
import UIKit

struct EditableProfileAvatar: View {
    let appState: AppState
    var size: CGFloat = 88
    var backgroundColor: Color = MedNexTheme.Colors.primary

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploading = false
    @State private var uploadError: String?
    @State private var showUploadError = false

    var body: some View {
        VStack(spacing: MedNexTheme.Spacing.xs) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    AvatarView(
                        name: appState.currentUser?.displayName ?? "User",
                        imageURL: appState.currentUser?.profileImageURL,
                        size: size,
                        backgroundColor: backgroundColor
                    )

                    Circle()
                        .fill(MedNexTheme.Colors.primary)
                        .frame(width: size * 0.30, height: size * 0.30)
                        .overlay {
                            Image(systemName: isUploading ? "arrow.triangle.2.circlepath" : "camera.fill")
                                .font(.system(size: size * 0.12, weight: .semibold))
                                .foregroundStyle(.white)
                                .symbolEffect(.rotate, isActive: isUploading)
                        }
                        .offset(x: -2, y: -2)
                }
            }
            .disabled(isUploading)

            Text(isUploading ? "Uploading..." : "Tap to add/change photo")
                .font(MedNexTheme.Typography.caption)
                .foregroundStyle(MedNexTheme.Colors.textSecondary)
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }
            Task {
                await uploadPhoto(from: newValue)
            }
        }
        .alert("Upload Failed", isPresented: $showUploadError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(uploadError ?? "Something went wrong while uploading your photo.")
        }
    }

    @MainActor
    private func uploadPhoto(from item: PhotosPickerItem) async {
        guard !isUploading else { return }
        guard let userId = appState.currentUser?.id else {
            uploadError = "Unable to find user account."
            showUploadError = true
            return
        }

        isUploading = true
        defer {
            isUploading = false
            selectedPhoto = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw ProfilePhotoError.failedToEncode
            }

            let imageURL = try await ProfilePhotoService.shared.uploadProfilePhoto(userId: userId, image: image)
            try await SupabaseService.shared.updateUserProfileImageURL(userId: userId, imageURL: imageURL)

            if var user = appState.currentUser {
                user.profileImageURL = imageURL
                appState.currentUser = user
            }

            HapticManager.success()
        } catch {
            HapticManager.error()
            uploadError = error.localizedDescription
            showUploadError = true
        }
    }
}
#endif
