import SwiftUI
import UIKit
import QuickLook

import UniformTypeIdentifiers
extension UTType {
    static let reality = UTType(exportedAs: "com.apple.reality")
}
import FirebaseAuth
import RealityKit

import Observation
import Foundation
import SwiftyJSON

import AVFoundation
    
struct ContentView: View {
    
    @Environment(ViewModel.self) private var model
    
    @State private var defaultSelectionForUserMenu: String? = "All"
    @State private var isLoggedIn = false
    @State private var selectedTab: TabItem = .home
    
    @StateObject var firebase = FirebaseViewModel()
    
    @ObservedObject var googleBooksAPI = GoogleBooksAPIRepository()
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: CGFloat(10), alignment: nil),
        GridItem(.flexible(), spacing: CGFloat(10), alignment: nil),
        GridItem(.flexible(), spacing: CGFloat(10), alignment: nil),
    ]
    
    enum TabItem: String, CaseIterable {
        case home = "house"
        case profile = "person.crop.circle"
        case post = "plus"
        
        var title: String {
            switch self {
            case .home: return "Home"
            case .profile: return "Profile"
            case .post: return "Post"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                Group {
                    if tab == .home {
                        HomeViewWrapper()
                    } else if tab == .profile && !firebase.isLoggedIn {
                        logInViewToPost()
                            .environmentObject(firebase)
                    } else if tab == .profile && firebase.isLoggedIn {
                        UserAllViewWrapper()
                    } else if tab == .post && !firebase.isLoggedIn {
                        SignUpView()
                            .environmentObject(firebase)
                    } else if tab == .post && firebase.isLoggedIn {
                        Add3DModelViewWrapper()
                    }
                }
                .tabItem {
                    Image(systemName: tab.rawValue)
                    Text(tab.title)
                }
                .tag(tab)
            }
        }
        .onAppear {
            selectedTab = .home
        }
    }

    struct HomeViewWrapper: View {
        var body: some View {
            NavigationStack {
                homeView()
            }
        }
    }

    struct UserAllViewWrapper: View {
        var body: some View {
            NavigationStack {
                userAllView()
            }
        }
    }
        
    struct Add3DModelViewWrapper: View {
        var body: some View {
            NavigationStack {
                Add3DModelView()
            }
        }
    }
    
    struct SupportViewWrapper: View {
        var body: some View {
            NavigationStack {
                SupportView()
            }
        }
    }
    
    struct SupportView: View {
        var body: some View {
            Text("takuzen0430@gmail.com")
        }
    }
    // MARK: - LogInView
    struct logInViewToProfile: View {
        
        @EnvironmentObject var firebase: FirebaseViewModel
        
        @State private var showingSuccessAlert = false
        @State private var successMessage = "Signed In Successfully."
        @State private var navigationTag: NavigationTag?
        
        enum NavigationTag {
            case signUp
            case userAllView
        }
        
        var body: some View {
            NavigationStack {
                VStack {
                    Text("Authentication")
                    
                    TextField("Email", text: $firebase.mail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .frame(width: 250.0, height: 100.0)
                    
                    SecureField("Password", text: $firebase.password)
                        .padding()
                        .frame(width: 250.0, height: 100.0)
                    
                    VStack {
                        Button(action: {
                            firebase.login { success, message in
                                if success {
                                    print("enter success logic")
                                    successMessage = message
                                    showingSuccessAlert = true
                                    print("showingSuccessAlert is toggled")
                                    firebase.isLoggedIn = true
                                } else {
                                    firebase.errorMessage = message
                                }
                            }
                        }) {
                            Text("Authenticate →")
                        }
                        .alert(
                            "Success",
                            isPresented: $showingSuccessAlert,
                            presenting: successMessage
                        ) { _ in
                            Button("OK") {
                                navigationTag = .userAllView
                            }
                        } message: { successMessage in
                            Text(successMessage)
                        }
                        
                        Text(firebase.errorMessage)
                        
                        Text("Create an account?")
                            .onTapGesture {
                                navigationTag = .signUp
                            }
                    }
                }
                .navigationDestination(for: NavigationTag.self) { tag in
                    switch tag {
                    case .signUp:
                        SignUpView()
                    case .userAllView:
                        UserAllViewWrapper()
                    }
                }
            }
        }
        
    }
    
    enum LogInDestination {
        case SignUpView
        case userHomeView
    }
    
    struct logInViewToPost: View {
        
        @EnvironmentObject var firebase: FirebaseViewModel
        
        @State private var showingSuccessAlert = false
        @State private var successMessage = "Signed In Successfully."
        @State private var navigationPath = NavigationPath()
        @State private var navigateToUserHome = false
        
        var body: some View {
            NavigationStack(path: $navigationPath) {
                VStack {
                    Text("Authentication")
                    
                    TextField("Email", text: $firebase.mail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .frame(width: 250.0, height: 100.0)
                    
                    SecureField("Password", text: $firebase.password)
                        .padding()
                        .frame(width: 250.0, height: 100.0)
                    
                    VStack {
                        Button(action: {
                            firebase.login { success, message in
                                if success {
                                    print("enter success logic")
                                    successMessage = message
                                    showingSuccessAlert = true
                                    print("showingSuccessAlert is toggled")
                                    firebase.isLoggedIn = true
                                } else {
                                    firebase.errorMessage = message                                }
                            }
                        }) {
                            Text("Authenticate →")
                        }
                        .alert(
                            "Success",
                            isPresented: $showingSuccessAlert,
                            presenting: successMessage
                        ) { _ in
                            Button("OK") {
                                navigateToUserHome = true
                            }
                        } message: { successMessage in
                            Text(successMessage)
                        }
                        
                        Text(firebase.errorMessage)
                        
                        NavigationLink(value: LogInDestination.SignUpView) {
                            Text("Create an account?")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .navigationDestination(for: LogInDestination.self) { destination in
                    switch destination {
                    case .SignUpView:
                        SignUpView()
                    case .userHomeView:
                        logInViewToProfile()
                    }
                }
            }
        }
    }
    
    enum SignUpDestination {
        case logInView
        case userHomeView
    }

    struct SignUpView: View {
        @EnvironmentObject var firebase: FirebaseViewModel
        @State private var showingSuccessAlert = false
        @State private var successMessage = "User registration has succeeded!"
        @State private var firstName: String = ""
        @State private var lastName: String = ""
        @State private var navigationPath = NavigationPath()
        @State private var navigateToUserHome = false

        var body: some View {
            NavigationStack(path: $navigationPath) {
                VStack {
                    Text("Registration")
                    
                    // First Name
                    TextField("First Name", text: $firstName)
                        .padding()
                        .frame(width: 250.0, height: 50.0)
                    
                    // Last Name
                    TextField("Last Name", text: $lastName)
                        .padding()
                        .frame(width: 250.0, height: 50.0)
                    
                    // Email
                    TextField("Email", text: $firebase.mail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .frame(width: 250.0, height: 50.0)
                    
                    // Password
                    SecureField("Password", text: $firebase.password)
                        .padding()
                        .frame(width: 250.0, height: 50.0)
                }
                
                VStack {
                    Button(action: {
                        // Update the sign-up process to include first & last name, and image
                        firebase.signUp(firstName: firstName, lastName: lastName) { success, message in
                            if success {
                                successMessage = message
                                showingSuccessAlert = true
                                firebase.isLoggedIn = true
                            } else {
                                firebase.errorMessage = message
                            }
                        }
                    }) {
                        Text("Authenticate →")
                    }
                    .alert(
                        "Success",
                        isPresented: $showingSuccessAlert,
                        presenting: successMessage
                    ) { _ in
                        Button("OK") {
                            navigateToUserHome = true
                        }
                    } message: { successMessage in
                        Text(successMessage)
                    }

                    Text(firebase.errorMessage)

                    // Navigate to LogInViewWrapper
                    NavigationLink(value: SignUpDestination.logInView) {
                        Text("Already have an account?")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            // Define how to handle navigation to LogInViewWrapper
            .navigationDestination(for: SignUpDestination.self) { destination in
                switch destination {
                case .logInView:
                    logInViewToProfile()
                case .userHomeView:
                    UserAllViewWrapper()
                }
            }
        }
    }
}

// MARK: - ContentView END

struct DetailView: View {
    
    @StateObject var firebase = FirebaseViewModel()
    
    var body: some View {
        // Safely unwrap the first item of the array
        if let firstMetadata = firebase.spatialVideoMetadataArray.first {
            // Prefer the localURL if available, otherwise fall back to the videoURL
            let url = firstMetadata.localURL ?? URL(string: firstMetadata.videoURL ?? "")
            
            Text("Detail no metadata")
                .onAppear {
                       print("firstMetadata.localURL is: \(firstMetadata.localURL)")
                   }
            
            // Safely unwrap the URL and create a URL object
            if let url = url {
                USDZQLPreview(url: url) // Display the video preview from the local URL
            } else {
                Text("Invalid or missing URL") // Show an error message if the URL is invalid or missing
            }
        } else {
            Text("Metadata is empty") // Show an error message if there are no metadata items
        }
    }
}



struct homeView: View {
    @ObservedObject var firebaseViewModel = FirebaseViewModel()
    
    @State private var fileURLs: [URL] = []
    
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    let customColor = Color(red: 0.988, green: 0.169, blue: 0.212)

        
    var body: some View {
        GeometryReader { geometry in
            VStack {

                HStack {
                    Image("teegarden-logo-nobg")
                        .resizable()
                        .frame(width: 30, height: 30)
                    Text("Teegarden")
                        .font(.system(size: 25))
                    Spacer()
                }
                .padding(.leading, 10)
                .padding(.top, 40)
                
                VStack {
                    HStack {
                        Text("Spatial Videos")
                            .font(.headline)
                            .padding(.leading)
                        Spacer()
                    }
                    .padding([.top, .leading], 10)
                    
                    Spacer()
                    
                    // Background color for ScrollView
                    ScrollView(.horizontal, showsIndicators: false) {
                        let rows = [GridItem(.flexible(minimum: 10, maximum: .infinity), spacing: 20)]
                        
                        LazyHGrid(rows: rows, spacing: 20) {
                            ForEach(firebaseViewModel.spatialVideoMetadataArray, id: \.thumbnailURL) { metadata in
                                NavigationLink(destination: DetailView()) {
                                    VStack {
                                        // User info and profile image
                                        HStack {
                                            if let profileImageURL = firebaseViewModel.userProfileImageURL {
                                                AsyncImage(url: profileImageURL) { image in
                                                    image.resizable()
                                                } placeholder: {
                                                    Image(systemName: "person.circle")
                                                        .resizable()
                                                        .frame(width: 40, height: 40)
                                                        .clipShape(Circle())
                                                }
                                                .scaledToFit()
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                            }
                                            
                                            Image(systemName: "person.circle")
                                                .resizable()
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                            
                                            Text("Username")
                                                .padding(.leading, 5)
                                                
                                            Spacer()
                                        }
                                        .padding(.bottom, 20)
                                        
                                        AsyncImage(url: URL(string: metadata.thumbnailURL)) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 600, height: 247.22)
                                                .clipped()
                                                .transition(.opacity)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        } else if phase.error != nil {
                                            Color.red
                                        } else {
                                            ZStack {
                                                Color.gray
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                
                                                VStack {
                                                    Spacer()
                                                    HStack {
                                                        ProgressView()
                                                            .frame(width: 840, height: 500)
                                                            .clipped()
                                                    }
                                                    Spacer()
                                                }
                                            }
                                        }
                                    }
                                        
                                        //if let caption = metadata.caption {
                                            Text("caption")
                                                .padding(.top, 20)
                                        //}
                                        
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .frame(width: 600, height: 800)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .frame(width: geometry.size.width, height: geometry.size.height / 1.5)
                    
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height / 3 * 2 + 100)
                .onAppear {
                    firebaseViewModel.fetchThumbnailsMetadata() { result in
                        switch result {
                        case .success(let thumbnails):
                            print("Successfully fetched thumbnails: \(thumbnails)")
                        case .failure(let error):
                            print("Error fetching thumbnails: \(error)")
                        }
                    }
                }
                .onReceive(timer) { _ in
                    firebaseViewModel.fetchThumbnailsMetadata() { result in
                        switch result {
                        case .success(let thumbnails):
                            print("Successfully fetched thumbnails: \(thumbnails)")
                        case .failure(let error):
                            print("Error fetching thumbnails: \(error)")
                        }
                    }
                }
                .padding()
            }
            Spacer()
        }
    }
}
    
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

/*
struct userObjectiveView: View {
    
}
 */

struct userAllView: View {
    @EnvironmentObject var firebase: FirebaseViewModel
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var posts: [Post] = []

    private func uploadImage() {
        guard let newImage = inputImage, let userId = firebase.currentUserId else { return }
        guard let imageData = newImage.imageData() else { return }

        firebase.uploadProfileImage(userId: userId, imageData: imageData) { imageURL in
            if let imageURL = imageURL {
                // Save the image URL in Firestore in the user's profile document
                firebase.updateProfileImageUrl(userId: userId, imageURL: imageURL) {
                    // Handle the result of the profile image URL update
                    // You can use a completion block or update your UI accordingly
                    print("Profile image URL updated successfully!")
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Profile Image
                if let inputImage = inputImage {
                    Image(uiImage: inputImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    VStack {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                        Button("Upload Profile Image") {
                            showingImagePicker = true
                        }
                    }
                }

                // Display user's first and last names (assumed to be properties of firebase)
                HStack {
                    Text(firebase.userFirstName)
                    Text(firebase.userLastName)
                }

                /// seems not linked to user yet
                if posts.isEmpty {
                    Text("Show us your spatial videos and archive them here!")
                        .padding()
                } else {
                    // A list of posts, each post has a thumbnail and optional caption
                    List(posts) { post in
                        VStack(alignment: .leading) {
                            Image(uiImage: UIImage(data: try! Data(contentsOf: post.thumbnailURL))!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            if let caption = post.caption {
                                Text(caption)
                            }
                        }
                    }
                }

                NavigationLink(destination: Add3DModelView()) {
                    Text("Post now →")
                        .padding()
                        .foregroundColor(Color.white)
                        .cornerRadius(8)
                }

                // Support email address
                HStack {
                    Text("Support: support@teegarden.app")
                    Image(systemName: "paperplane")
                }
                
                // Sign Out button
                Button("Sign Out") {
                    firebase.signOut()
                    /// not working now
                }
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.red)

                Spacer()
            }
            .navigationTitle("My Space")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingImagePicker, onDismiss: uploadImage) {
                ImagePicker(selectedImage: $inputImage)
            }
        }
    }
}

struct Book: Identifiable {
    let id: String
    let volumeInfo: JSON
    let thumnailUrl: String
    let title: String
    let description: String
}

struct Post: Identifiable {
    var id: String
    var creatorUserID: String
    var thumbnailURL: URL
    var caption: String?
    var creationDate: Date?
}

struct User: Identifiable {
    var id: String
    var profileImageURL: URL
    var username: String
    var firstName: String
    var lastName: String
    var posts: [Post]
}

class FeedModel: ObservableObject {
    @Published var posts: [Post] = []
    
    func addPost(_ post: Post, completion: @escaping (Bool) -> Void) {
        posts.insert(post, at: 0)
    }

}

struct USDZQLPreview: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        return previewController
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        // No need to update
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL

        init(url: URL) {
            self.url = url
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
                return url as QLPreviewItem
        }
    }
}

enum FileSaveError: Error {
    case fileExists
}

func saveModelToTemporaryFolder(modelURL: URL, thumbnailURL: URL?, overwrite: Bool) async -> Result<(model: URL, thumbnail: URL?), Error> {
    let fileManager = FileManager.default
    
    // Get the documents directory URL
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    // Create a URL for the "TmpModelFiles" directory
    let tmpModelFilesDirectory = documentsDirectory.appendingPathComponent("TmpModelFiles")
    
    // Create the "TmpModelFiles" directory if it doesn't exist
    if !fileManager.fileExists(atPath: tmpModelFilesDirectory.path) {
        do {
            try fileManager.createDirectory(at: tmpModelFilesDirectory, withIntermediateDirectories: true)
        } catch {
            return .failure(error)
        }
    }
    
    // Define the destination URL for the model file
    let modelDestinationURL = tmpModelFilesDirectory.appendingPathComponent(modelURL.lastPathComponent)
    
    // Check if the model file exists
    if fileManager.fileExists(atPath: modelDestinationURL.path) {
        // If overwrite is false, return failure
        guard overwrite else {
            return .failure(FileSaveError.fileExists)
        }
        // If overwrite is true, remove the existing file
        do {
            try fileManager.removeItem(at: modelDestinationURL)
        } catch {
            return .failure(error)
        }
    }
    
    // Copy the model file to the destination
    do {
        try fileManager.copyItem(at: modelURL, to: modelDestinationURL)
    } catch {
        return .failure(error)
    }
    
    var tmpThumbnailURL: URL?
    
    // Process thumbnailURL if it's not nil
    if let thumbnailURL = thumbnailURL {
        let thumbnailDestinationURL = tmpModelFilesDirectory.appendingPathComponent(thumbnailURL.lastPathComponent)
        
        // Check if the thumbnail file exists
        if fileManager.fileExists(atPath: thumbnailDestinationURL.path) {
            // If overwrite is false, return failure
            guard overwrite else {
                return .failure(FileSaveError.fileExists)
            }
            // If overwrite is true, remove the existing file
            do {
                try fileManager.removeItem(at: thumbnailDestinationURL)
            } catch {
                return .failure(error)
            }
        }
        
        // Copy the thumbnail file to the destination
        do {
            try fileManager.copyItem(at: thumbnailURL, to: thumbnailDestinationURL)
            tmpThumbnailURL = thumbnailDestinationURL
        } catch {
            return .failure(error)
        }
    }
    
    // Return success with the URL of the model and the thumbnail (if it exists)
    return .success((model: modelDestinationURL, thumbnail: tmpThumbnailURL))
}


func loadModelsFromTemporaryFolder() -> [URL] {
    // Get the documents directory URL
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let tmpModelFilesDirectory = documentsDirectory.appendingPathComponent("TmpModelFiles")
    
    do {
        // Get the directory contents URLs (including subfolders URLs)
        let directoryContents = try FileManager.default.contentsOfDirectory(at: tmpModelFilesDirectory, includingPropertiesForKeys: nil)
        
        // Filter the directory contents for files with the 'usdz' file extension
        let allowedExtensions = ["usdz", "reality", "mov"]
        let spatialFiles = directoryContents.filter { allowedExtensions.contains($0.pathExtension) }
        
        // Return the array of 'usdz' file URLs
        return spatialFiles
        
    } catch {
        return []
    }
}
// MARK: - Add3DModelView
struct Add3DModelView: View {
    @State private var isPickerPresented = false
    @State private var selectedModelURL: URL?
    @State private var confirmedModelURL: URL?
    @State private var confirmedThumbnailURL: URL?
    @State private var savedModelURL: URL?
    @State private var savedThumbnailURL: URL?
    @State private var captionText: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoadingModel = false
    @State private var isPreviewing = false
    @State private var isPostingSuccessful: Bool = false
    @State private var showOverwriteAlert = false
    @State private var shouldOverwriteFile = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var thumbnailURL: URL?
    
    let allowedContentTypes: [UTType] = [.usdz, .reality, .movie]
    
    func handleModelSelection(urls: [URL], shouldOverwrite: Bool = false) {
        print("handleModelSelection called with URLs: \(urls)")
        guard let firstModelURL = urls.first else {
            print("No URL found in the array.")
            return
        }
        print("First model URL: \(firstModelURL)")
        
        let canAccess = firstModelURL.startAccessingSecurityScopedResource()
        print("Can access firstModelURL: \(canAccess)")
        
        if canAccess {
            if firstModelURL.pathExtension.lowercased() == "mov" {
                generateThumbnail(url: firstModelURL) { thumbnailURL in
                    DispatchQueue.main.async {
                        self.thumbnailURL = thumbnailURL
                        if let thumbnailURL = thumbnailURL {
                            print("Thumbnail URL has been set!")
                            self.processModel(thumbnailURL: thumbnailURL, originalURL: firstModelURL, shouldOverwrite: shouldOverwrite)
                        } else {
                            print("Failed to set thumbnail URL.")
                            self.showAlertWith(message: "Failed to generate thumbnail for the video.")
                        }
                    }
                }
            } else {
                processModel(thumbnailURL: thumbnailURL, originalURL: firstModelURL, shouldOverwrite: shouldOverwrite)
            }
        } else {
            DispatchQueue.main.async {
                self.alertMessage = "You don't have permission to access the file."
                self.showAlert = true
            }
        }
    }

    func processModel(thumbnailURL: URL?, originalURL: URL, shouldOverwrite: Bool) {
        Task {
            let thumbnailUrlReadyForSavingToTmp = thumbnailURL
            let modelUrlReadyForSavingToTmp = originalURL
            print(modelUrlReadyForSavingToTmp)
            print(thumbnailUrlReadyForSavingToTmp)
            let result = await saveModelToTemporaryFolder(modelURL: modelUrlReadyForSavingToTmp, thumbnailURL: thumbnailUrlReadyForSavingToTmp, overwrite: shouldOverwrite)
            print(result)
            
            switch result {
            case .success(let savedURL):
                DispatchQueue.main.async { /// what does this mean DispatchQue.main.async, async and await are not understood.
                    print(savedURL.model)
                    print(savedURL.thumbnail)
                    self.savedModelURL = savedURL.model
                    self.savedThumbnailURL = savedURL.thumbnail
                    self.isPreviewing = true
                    print("isPreviewing = true")
                    shouldOverwriteFile = false
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    if let fileSaveError = error as? FileSaveError, fileSaveError == .fileExists {
                        self.showOverwriteAlert = true
                    } else {
                        self.alertMessage = error.localizedDescription
                        self.showAlert = true
                    }
                    shouldOverwriteFile = false
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
    
    private func postModel(with confirmedURL: URL, thumbnailURL: URL?) {
        let fileType = confirmedURL.pathExtension.lowercased()
        isLoadingModel = true
        
        FirebaseViewModel.shared.uploadCube(modelURL: confirmedURL, thumbnailURL: thumbnailURL, fileType: fileType) { result in
            isLoadingModel = false
            switch result {
            case .success(let urls):
                print("Model and thumbnail uploaded successfully. Model URL: \(urls.modelURL), Thumbnail URL: \(String(describing: urls.thumbnailURL))")
            case .failure(let error):
                print("Upload failed with error: \(error.localizedDescription)")
                // Handle the error, update UI, etc.
            }
        }
    }

    struct ModelPreviewView: View {
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
                                Spacer()
                                Button(action: { isPreviewing = false }) {
                                    Label("", systemImage: "xmark")
                                }
                            }
                            
                            if url.pathExtension.lowercased() == "usdz" || url.pathExtension.lowercased() == "reality" {
                                Model3D(url: url) { model in
                                    model
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 200, height: 200)
                                    
                                } placeholder: {
                                        ProgressView()
                                }
                                .padding()
                            } else if url.pathExtension.lowercased() == "mov", let thumbnail = savedThumbnailURL {
                                AsyncImage(url: thumbnail) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 200, height: 200)
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                Text("Unsupported file type or no preview available")
                            }
                            
                            Button("Confirm") {
                                confirmedModelURL = savedModelURL
                                confirmedThumbnailURL = savedThumbnailURL
                                isPreviewing = false
                            }
                            .padding()
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            Button("Cancel") {
                                isPreviewing = false
                            }
                            .padding()
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                } else {
                    Text("Hello, no spatial contents available.")
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            if let modelURL = confirmedModelURL {
                VStack {
                    if modelURL.pathExtension.lowercased() == "mov", let thumbnail = confirmedThumbnailURL {
                        AsyncImage(url: thumbnail) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 300, height: 300)
                        } placeholder: {
                            ProgressView()
                        }
                    } else {
                        Model3D(url: modelURL) { model in
                            model
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200, height: 200)
                            
                        } placeholder: {
                            if isLoadingModel {
                                ProgressView()
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                            if isLoadingModel {
                                                alertMessage = "Loading timeout. Please try a different model."
                                                showAlert = true
                                                isLoadingModel = false
                                            }
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                    
                    /*
                    
                    Button("Re-select") {
                        isPickerPresented = true
                    }
                    .padding()
                     
                    */
                    
                    TextField("Write a caption...", text: $captionText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    HStack {
                        Spacer()
                        Button("Post →") {
                            if let confirmedURL = confirmedModelURL {
                                postModel(with: confirmedURL, thumbnailURL: confirmedThumbnailURL)
                                isPostingSuccessful = true
                            } else {
                                alertMessage = "Please confirm the model before posting."
                                showAlert = true
                            }
                        }
                        .padding()
                        .alert(isPresented: $showAlert) {
                            Alert(
                                title: Text(alertTitle),
                                message: Text(alertMessage),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                        .padding()
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
                            handleModelSelection(urls: urls)
                        case .failure(let error):
                            alertMessage = "Error selecting file: \(error.localizedDescription)"
                            showAlert = true
                        }
                    }
                    .padding()
                    
                    TextField("Write a caption...", text: $captionText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    HStack {
                        Spacer()
                        Button("Post →") {
                            if let confirmedURL = confirmedModelURL {
                                postModel(with: confirmedURL, thumbnailURL: confirmedThumbnailURL)
                                isPostingSuccessful = true
                            } else {
                                alertMessage = "Please confirm the model before posting."
                                showAlert = true
                            }
                        }
                        .padding()
                        .alert(isPresented: $showAlert) {
                            Alert(
                                title: Text(alertTitle),
                                message: Text(alertMessage),
                                dismissButton: .default(Text("OK"))
                            )
                        }

                        .padding()
                        .alert(isPresented: $showAlert) {
                            Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                        }
                        .alert(isPresented: $showOverwriteAlert) {
                            Alert(
                                title: Text("The file already exists."),
                                primaryButton: .destructive(Text("Overwrite")) {
                                    // User confirms to overwrite the file
                                    shouldOverwriteFile = true
                                    // Call the function to handle the model selection again with overwrite allowed
                                    if let selectedModelURL = selectedModelURL {
                                        handleModelSelection(urls: [selectedModelURL], shouldOverwrite: true)
                                    }
                                },secondaryButton: .cancel(Text("Cancel")))
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Post")
        .sheet(isPresented: $isPreviewing) {
            ModelPreviewView(
                    savedModelURL: $savedModelURL,
                    savedThumbnailURL: $savedThumbnailURL,
                    isPreviewing: $isPreviewing,
                    confirmedModelURL: $confirmedModelURL, // Pass the binding
                    confirmedThumbnailURL: $confirmedThumbnailURL
            )
        }
    }
}


class GoogleBooksAPIRepository: ObservableObject {
    @Published var query: String = ""
    @Published var booksResult: [Book] = []
    
    let endpoint = "https://www.googleapis.com/books/v1"

    enum GoogleBooksAPIError : Error {
        case invalidURLString
        case notFound
    }
    
    public func getBooks() async {
            let data = try! await downloadData(urlString: "\(endpoint)/volumes?q=\(query)")
            let json = JSON(data)
            let result = await self.setVolume(json)
            DispatchQueue.main.async {
                self.booksResult = result
            }
        }
        
        public func getBookById(bookId:String) async {
            let data = try! await downloadData(urlString: "\(endpoint)/volumes/\(query)")
            let json = JSON(data)
            let result = await self.setVolume(json)
            DispatchQueue.main.async {
                self.booksResult = result
            }
        }

        private func setVolume(_ json: JSON) async -> [Book] {
            let items = json["items"].array!
            var books: [Book] = []
            for item in items {
                let bk = Book(
                    id: item["id"].stringValue,
                    volumeInfo: item["volumeInfo"],
                    thumnailUrl: item["volumeInfo"]["imageLinks"]["thumbnail"].stringValue,
                    title: item["volumeInfo"]["title"].stringValue,
                    description: item["volumeInfo"]["description"].stringValue
                )
            }
            return books
        }

        final func downloadData(urlString:String) async throws -> Data {
            guard let url = URL(string: urlString) else {
                throw GoogleBooksAPIError.invalidURLString
            }
            let (data,_) = try await URLSession.shared.data(from: url)
            return data
        }
    }

func url(s: String) -> String{
    var i = s
    if(!i.hasPrefix("http")){return ""}
    let insertIdx = i.index(i.startIndex, offsetBy: 4)
    i.insert(contentsOf: "s", at: insertIdx)
    return i
}

struct CategorySelectionView: View {
    var body: some View {
        VStack(alignment: .leading) {
            NavigationLink(destination: BookSearchView(googleBooksAPI: GoogleBooksAPIRepository())) {
                Text("Books")
                    .padding()
                    .foregroundColor(Color.white)
                    .cornerRadius(2)
            }
            
            NavigationLink(destination: Add3DModelView()) {
                Text("My Own 3D Model")
                    .padding()
                    .foregroundColor(Color.white)
                    .cornerRadius(2)
            }
        }
    }
}
    
struct BookSearchView: View {
    @ObservedObject var googleBooksAPI: GoogleBooksAPIRepository
    @EnvironmentObject var viewModel: FirebaseViewModel
    
    var body: some View {
        TextField("Search for books", text: $googleBooksAPI.query, onCommit: {
            Task {
                await googleBooksAPI.getBooks()
            }
        })
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding()
    }
}

/*
 #Preview {
 ContentView()
 }
*/
