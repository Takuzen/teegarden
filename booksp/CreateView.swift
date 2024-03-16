//
//  CreateView.swift
//  booksp
//
//  Created by Takuzen Toh on 3/16/24.
//

import SwiftUI
import AVKit
import Firebase

class AlertViewModel: ObservableObject {
    @Published var showOverwriteAlert: Bool = false
    @Published var alertMessage: String = ""
    // Other alert-related states can be added here
}

struct CreateView: View {
    @StateObject private var alertViewModel = AlertViewModel()
    
    @State private var isPickerPresented = false
    @State private var selectedModelURL: URL?
    @State private var confirmedModelURL: URL?
    @State private var confirmedThumbnailURL: URL?
    @State private var savedModelURL: URL?
    @State private var savedThumbnailURL: URL?
    @State private var captionText: String = ""
    @State private var isEditing: Bool = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoadingModel = false
    @State private var isPreviewing = false
    @State private var isPostBtnClicked = false
    @State private var isUploading = false
    @State private var isPostingSuccessful: Bool = false
    @State private var navigateToHome = false
    @State private var shouldOverwriteFile = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var thumbnailURL: URL?
    @State private var isFileSizeLimitExceeded = false
    
    @Environment(\.presentationMode) var presentationMode
    
    @EnvironmentObject private var firebase: FirebaseViewModel
    
    let allowedContentTypes: [UTType] = [.usdz, .reality, .movie]
    
    func clearTemporaryModelFilesFolder() {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let tmpModelFilesDirectory = documentsDirectory.appendingPathComponent("TmpModelFiles")
        
        // Check if the directory exists before trying to delete it
        if fileManager.fileExists(atPath: tmpModelFilesDirectory.path) {
            do {
                try fileManager.removeItem(at: tmpModelFilesDirectory)
                print("Cleared TmpModelFiles folder.")
            } catch {
                print("Could not clear TmpModelFiles folder: \(error)")
            }
        }
    }
    
    func handleCubeSelection(urls: [URL], shouldOverwrite: Bool = false) {
        guard let firstModelURL = urls.first else {
            return
        }

        let canAccess = firstModelURL.startAccessingSecurityScopedResource()

        defer {
            firstModelURL.stopAccessingSecurityScopedResource()
        }

        guard canAccess else {
            DispatchQueue.main.async {
                self.alertMessage = "You don't have permission to access the file."
                self.showAlert = true
            }
            return
        }

        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent(firstModelURL.lastPathComponent)

        do {
            if FileManager.default.fileExists(atPath: tempFileURL.path) {
                try FileManager.default.removeItem(at: tempFileURL)
            }
            try FileManager.default.copyItem(at: firstModelURL, to: tempFileURL)

            let fileAttributes = try FileManager.default.attributesOfItem(atPath: tempFileURL.path)
            if let fileSize = fileAttributes[.size] as? NSNumber, fileSize.intValue > 104857600 {
                // File size exceeds the limit, show an alert
                DispatchQueue.main.async {
                    self.showAlertWith(message: "Your file seems to exceed 100MB.")
                }
                return
            }
        } catch {
            DispatchQueue.main.async {
                self.showAlertWith(message: "Failed to access or copy the file.")
            }
            return
        }

        // Process the file using the temporary URL
        switch tempFileURL.pathExtension.lowercased() {
        case "mov":
            print("Handling a .mov file")
            generateThumbnail(url: tempFileURL) { thumbnailURL in
                DispatchQueue.main.async {
                    self.thumbnailURL = thumbnailURL
                    if let thumbnailURL = thumbnailURL {
                        print("Thumbnail URL has been set!")
                        self.processModel(thumbnailURL: thumbnailURL, originalURL: tempFileURL, shouldOverwrite: shouldOverwrite)
                    } else {
                        print("Failed to set thumbnail URL.")
                        self.showAlertWith(message: "Failed to generate thumbnail for the video.")
                    }
                }
            }
        case "usdz", "reality":
            print("Handling a .usdz or .reality file")
            // For usdz and reality files, directly process the model without a thumbnail
            self.processModel(thumbnailURL: nil, originalURL: tempFileURL, shouldOverwrite: shouldOverwrite)
        default:
            DispatchQueue.main.async {
                self.showAlertWith(message: "Unsupported file type.")
            }
        }
    }


    func processModel(thumbnailURL: URL?, originalURL: URL, shouldOverwrite: Bool) {
        Task {
            let thumbnailUrlReadyForSavingToTmp = thumbnailURL
            let modelUrlReadyForSavingToTmp = originalURL

            let result = await saveModelToTemporaryFolder(modelURL: modelUrlReadyForSavingToTmp, thumbnailURL: thumbnailUrlReadyForSavingToTmp, overwrite: shouldOverwrite)
            print(result)
            
            switch result {
            case .success(let savedURL):
                DispatchQueue.main.async { /// what does this mean DispatchQue.main.async, async and await are not understood.
                    self.savedModelURL = savedURL.model
                    self.savedThumbnailURL = savedURL.thumbnail
                    self.isPreviewing = true
                    print("isPreviewing = true")
                    shouldOverwriteFile = false
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    if let fileSaveError = error as? FileSaveError, fileSaveError == .fileExists {
                        print("Setting showOverwriteAlert to true")
                        self.alertViewModel.showOverwriteAlert = true
                        print("showOverwriteAlert: \(self.alertViewModel.showOverwriteAlert)")
                    } else {
                        self.alertViewModel.alertMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    func showAlertWith(message: String) {
        DispatchQueue.main.async {
            self.alertMessage = message
            self.showAlert = true
        }
    }

    func generateThumbnail(url: URL, completion: @escaping (URL?) -> Void) {
        let asset = AVAsset(url: url)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter = .zero
        assetImgGenerate.requestedTimeToleranceBefore = .zero
        
        let time = CMTimeMake(value: 1, timescale: 60)
        
        assetImgGenerate.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, image, _, _, error in
            guard let image = image, error == nil else {
                print("Error generating thumbnail: \(error?.localizedDescription ?? "N/A")")
                completion(nil)
                return
            }
            
            // Convert CGImage to UIImage
            let uiImage = UIImage(cgImage: image)
            
            // Save UIImage to disk and get URL
            if let data = uiImage.jpegData(compressionQuality: 0.8) {
                do {
                    // Create a unique URL for the image in the temporary directory
                    let filename = UUID().uuidString + ".jpg"
                    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                    
                    // Write the data to the URL
                    try data.write(to: fileURL)
                    print("Thumbnail image saved to: \(fileURL)")
                    completion(fileURL)
                } catch {
                    print("Error saving image: \(error)")
                    completion(nil)
                }
            } else {
                print("Could not convert UIImage to Data")
                completion(nil)
            }
        }
    }

    struct CubePreviewView: View {
        
        @Binding var savedModelURL: URL?
        @Binding var savedThumbnailURL: URL?
        @Binding var isPreviewing: Bool
        @Binding var confirmedModelURL: URL?
        @Binding var confirmedThumbnailURL: URL?
        
        var body: some View {
            VStack {
                
                if let url = savedModelURL {
                    
                    NavigationView {
                        
                        VStack {
                            
                            HStack {
                                
                                Button(action: { isPreviewing = false }) {
                                    Label("", systemImage: "xmark")
                                        .padding(.leading, 5)
                                }
                                .clipShape(Circle())
                                .offset(x: 15, y: 20)

                                Spacer()
                            }
                            
                            USDZQLPreview(url: url)
                                .padding()
                                .frame(width: 700, height: 437.5)
                            
                            HStack {
                                
                                Spacer()
                                
                                Button("Confirm") {
                                    confirmedModelURL = savedModelURL
                                    confirmedThumbnailURL = savedThumbnailURL
                                    isPreviewing = false
                                }
                                .padding(.trailing, 30)
                                .padding(.bottom, 30)
                                .cornerRadius(8)
                                
                            }
                        }
                    }
                    .frame(width: 900, height: 562.5)
                } else {
                    Text("Hello, no spatial contents available.")
                }
            }
        }
    }

    var body: some View {
        ScrollView(.vertical) {
            NavigationStack {
                if let modelURL = confirmedModelURL {
                    VStack {
                        if modelURL.pathExtension.lowercased() == "mov", let thumbnail = confirmedThumbnailURL {
                            AsyncImage(url: thumbnail) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 800, height: 500)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            
                            USDZQLPreview(url:modelURL)
                                .frame(width: 800, height: 500)
                        
                        }
                        
                        Button(action: {
                            confirmedModelURL = nil
                        }) {
                            Text("Dismiss selection")
                                .padding()
                                .cornerRadius(10)
                        }
                        .padding()
                        
                        ZStack(alignment: .topLeading) {
                            
                            if captionText.isEmpty && !isEditing {
                                Text("Caption...")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                                    .padding(.top, 8)
                                
                            }
                            
                            TextEditor(text: $captionText)
                                .padding(4)
                                .onTapGesture {
                                    isEditing = true
                                }
                            
                        }
                        .frame(width: 800, height: 100)
                        .border(Color(UIColor.separator), width: 4)
                        .cornerRadius(8)
                        .padding()
                        .onAppear {
                            UITextView.appearance().backgroundColor = .clear
                        }
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            Button("Post →") {
                                isPostBtnClicked = true
                                isUploading = true
                                if let confirmedMainURL = confirmedModelURL {
                                    let fileType = confirmedMainURL.pathExtension.lowercased()
                                    let thumbnailURL = (fileType == "mov") ? confirmedThumbnailURL : nil
                                    
                                    firebase.uploadFileAndThumbnail(fileURL: confirmedMainURL, thumbnailURL: thumbnailURL, fileType: fileType) { fileDownloadURL, thumbnailDownloadURL in
                                        
                                        guard let fileDownloadURL = fileDownloadURL else {
                                            DispatchQueue.main.async {
                                                alertMessage = "Failed to upload the file."
                                                showAlert = true
                                            }
                                            return
                                        }
                                        
                                        guard let userID = Auth.auth().currentUser?.uid else {
                                            DispatchQueue.main.async {
                                                alertMessage = "You need to be logged in to post."
                                                showAlert = true
                                            }
                                            return
                                        }
                                        
                                        let thumbnailURLString = thumbnailDownloadURL?.absoluteString ?? ""
                                        
                                        firebase.createPost(forUserID: userID, videoURL: fileDownloadURL.absoluteString, thumbnailURL: thumbnailURLString, caption: captionText, fileType: fileType)
                                        
                                        DispatchQueue.main.async {
                                            
                                            isUploading = false
                                            
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                self.isPostingSuccessful = true
                                                self.clearTemporaryModelFilesFolder()
                                            }
                                            
                                        }
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        alertMessage = "Please confirm the file before posting."
                                        showAlert = true
                                    }
                                }
                            }
                            .padding()
                            .sheet(isPresented: $isUploading) {
                                // This is the sheet that will show the uploading progress
                                VStack {
                                    Text("Uploading...")
                                        .font(.title)
                                        .padding()
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .scaleEffect(1.5)
                                        .padding()
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemBackground).opacity(0.9))
                                .edgesIgnoringSafeArea(.all)
                                .padding(30)
                            }
                        }
                        .padding()
                    }
                    
                } else {
                    
                    VStack {
                        
                        Text("No model selected")
                            .padding()
                        
                        Button("Choose A Spatial File") {
                            isPickerPresented = true
                        }
                        .fileImporter(
                            isPresented: $isPickerPresented,
                            allowedContentTypes: allowedContentTypes,
                            allowsMultipleSelection: false
                        ) { result in
                            switch result {
                            case .success(let urls):
                                isLoadingModel = true
                                selectedModelURL = urls.first
                                handleCubeSelection(urls: urls)
                            case .failure(let error):
                                alertMessage = "Error selecting file: \(error.localizedDescription)"
                                showAlert = true
                            }
                        }
                        .alert(
                            Text("The file already exists."),
                            isPresented: $alertViewModel.showOverwriteAlert
                        ) {
                            Button(role: .destructive) {
                                if let selectedModelURL = selectedModelURL {
                                    handleCubeSelection(urls: [selectedModelURL], shouldOverwrite: true)
                                }
                            } label: {
                                Text("Overwrite")
                            }
                            Button("Cancel", role: .cancel) {}
                        }
                        
                        .sheet(isPresented: $isPreviewing) {
                            CubePreviewView(
                                savedModelURL: $savedModelURL,
                                savedThumbnailURL: $savedThumbnailURL,
                                isPreviewing: $isPreviewing,
                                confirmedModelURL: $confirmedModelURL,
                                confirmedThumbnailURL: $confirmedThumbnailURL
                            )
                        }
                        
                        Text("Supported file formats include MOV/MV-HEVC, USDZ, and REALITY.")
                            .padding(.top, 5)

                        Text("The file size limit is 100MB.")
                        
                        ZStack(alignment: .topLeading) {
                            if captionText.isEmpty && !isEditing {
                                Text("Caption...")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 5)
                                    .padding(.top, 8)
                            }
                            TextEditor(text: $captionText)
                                .padding(4)
                                .onTapGesture {
                                    isEditing = true
                                }
                        }
                        .frame(width: 800, height: 100)
                        .border(Color(UIColor.separator), width: 4)
                        .cornerRadius(8)
                        .padding()
                        .onAppear {
                            UITextView.appearance().backgroundColor = .clear
                        }
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            Button("Post →") {}
                                .disabled(true)
                                .padding()
                        }
                    }
                    .padding()
                }
            }
        }
        .actionSheet(isPresented: $isPostingSuccessful) {
            ActionSheet(
                title: Text("Successfully posted!"),
                buttons: [
                    .default(Text("OK")) {
                        confirmedModelURL = nil
                        
                        captionText = ""
                    }
                ]
            )
        }
        
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertMessage),
                message: Text(""),
                dismissButton: .default(Text("OK")) {
                }
            )
        }

        .navigationTitle("Post")
    }
}
