//
//  UserfieldFileInput.swift
//  Grocy Mobile
//
//  Created by Georg Meissner on 20.11.26.
//

import ImageIO
import PhotosUI
import QuickLook
import SwiftUI
import UniformTypeIdentifiers

/// A file or picture userfield: shows the file (a picture as a preview), opens it, and picks, takes or removes one.
/// New files are kept in `changes` and only uploaded when the form is saved.
struct UserfieldFileInput: View {
    @Environment(GrocyViewModel.self) private var grocyVM

    let field: MDUserField
    /// The current value: the saved one, or the edited one.
    let value: String
    /// The value on the server, whose file is deleted when it's replaced.
    let savedValue: String?
    @Binding var changes: UserfieldChanges

    @State private var pictureData: Data?
    @State private var pickedPhoto: PhotosPickerItem?
    @State private var showFileImporter = false
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var previewURL: URL?
    @State private var isLoading = false

    private var isPicture: Bool { field.fieldType == .image }
    private var hasFile: Bool { MDUserField.encodedStoredFileName(of: value) != nil }
    /// The data of a picked file that isn't uploaded yet.
    private var pendingData: Data? {
        MDUserField.encodedStoredFileName(of: value).flatMap { changes.uploads[$0] }
    }

    var body: some View {
        // One row like the other fields: the caption, and the picture or file name, which opens the actions.
        LabeledContent {
            Menu {
                actions
            } label: {
                preview
            }
            .disabled(isLoading)
        } label: {
            Label {
                Text(LocalizedStringKey(field.caption))
            } icon: {
                Image(systemName: (field.fieldType ?? .file).symbol)
            }
            .foregroundStyle(.primary)
        }
        .task(id: value) {
            await loadPicture()
        }
        .onChange(of: pickedPhoto) {
            Task { await pickPhoto() }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $pickedPhoto, matching: .images)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item]) { result in
            pickFile(result)
        }
        .quickLookPreview($previewURL)
        #if os(iOS)
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker(sourceType: .camera) { image in
                    if let data = image.jpegData(compressionQuality: 1).flatMap({ uprightJPEG(from: $0) }) {
                        changes.setFile(data, named: "\(UUID().uuidString).jpg", for: field.name, savedValue: savedValue)
                    }
                }
            }
        #endif
    }

    /// The picture as a thumbnail, the file's name, or "None".
    @ViewBuilder
    private var preview: some View {
        if !hasFile {
            Text("None")
                .foregroundStyle(.secondary)
        } else if isPicture, let image = pictureData.flatMap(Image.init(data:)) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: Sizes.userfieldThumbnail, height: Sizes.userfieldThumbnail)
                .clipShape(.rect(cornerRadius: Spacing.small))
        } else if isPicture {
            ProgressView()
        } else {
            Text(verbatim: MDUserField.fileName(of: value))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    @ViewBuilder
    private var actions: some View {
        if hasFile {
            Button(isPicture ? "Show picture" : "Open file", systemImage: MySymbols.openFile) {
                Task { await openFile() }
            }
        }
        if isPicture {
            Button("Select picture from gallery", systemImage: MySymbols.gallery) {
                showPhotoPicker = true
            }
            #if os(iOS)
                Button("Take picture", systemImage: MySymbols.camera) {
                    showCamera = true
                }
            #endif
        } else {
            Button("Select file", systemImage: MySymbols.userfieldFile) {
                showFileImporter = true
            }
        }
        if hasFile {
            Divider()
            Button("Remove", systemImage: MySymbols.delete, role: .destructive) {
                changes.removeFile(of: field.name, savedValue: savedValue)
            }
        }
    }

    // MARK: - Loading

    private func loadPicture() async {
        guard isPicture, hasFile else {
            pictureData = nil
            return
        }
        if let pendingData {
            pictureData = pendingData
            return
        }
        do {
            pictureData = try await grocyVM.getUserfieldFile(value: value, bestFitWidth: Int(Sizes.userfieldThumbnail * 3))
        } catch {
            GrocyLogger.error("Loading the picture of userfield \(field.name) failed. \(error)")
        }
    }

    /// Downloads the file into the temporary folder under its own name and shows it with Quick Look.
    private func openFile() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var data = pendingData
            if data == nil {
                data = try await grocyVM.getUserfieldFile(value: value)
            }
            guard let data else { return }
            let url = FileManager.default.temporaryDirectory.appending(path: MDUserField.fileName(of: value))
            try data.write(to: url)
            previewURL = url
        } catch {
            GrocyLogger.error("Opening the file of userfield \(field.name) failed. \(error)")
        }
    }

    // MARK: - Picking

    private func pickPhoto() async {
        guard let pickedPhoto else { return }
        do {
            if let data = try await pickedPhoto.loadTransferable(type: Data.self), let jpeg = uprightJPEG(from: data) {
                changes.setFile(jpeg, named: "\(UUID().uuidString).jpg", for: field.name, savedValue: savedValue)
            }
        } catch {
            GrocyLogger.error("Loading the picked picture failed. \(error)")
        }
        self.pickedPhoto = nil
    }

    private func pickFile(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing { url.stopAccessingSecurityScopedResource() }
            }
            do {
                changes.setFile(try Data(contentsOf: url), named: url.lastPathComponent, for: field.name, savedValue: savedValue)
            } catch {
                GrocyLogger.error("Reading the picked file failed. \(error)")
            }
        case .failure(let error):
            GrocyLogger.error("Picking a file failed. \(error)")
        }
    }
}

/// A picture as an upright JPEG of at most `maxPixelSize` pixels. Grocy scales pictures on the server
/// and ignores their orientation, so a photo with an orientation tag would be shown rotated.
nonisolated func uprightJPEG(from data: Data, maxPixelSize: Int = 2048) -> Data? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
        let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            ] as CFDictionary
        )
    else { return nil }
    let output = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else { return nil }
    CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.8] as CFDictionary)
    return CGImageDestinationFinalize(destination) ? output as Data : nil
}

extension Image {
    /// A picture from image data, on iOS and macOS.
    init?(data: Data) {
        #if os(iOS)
            guard let image = UIImage(data: data) else { return nil }
            self.init(uiImage: image)
        #elseif os(macOS)
            guard let image = NSImage(data: data) else { return nil }
            self.init(nsImage: image)
        #endif
    }
}
