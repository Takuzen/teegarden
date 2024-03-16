import SwiftUI
import UIKit
import QuickLook

import UniformTypeIdentifiers
extension UTType {
    static let reality = UTType(exportedAs: "com.apple.reality")
}

import Firebase
import FirebaseFirestore

import RealityKit

import Observation
import Foundation
import SwiftyJSON

import AVFoundation
import AVKit
    
struct ContentView: View {
    
    @State private var defaultSelectionForUserMenu: String? = "All"
    @State private var selectedTab: TabItem = .home
    
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
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                .tag(TabItem.home)

            Group {
                if FirebaseViewModel.shared.isLoggedIn {
                    UserViewWrapper(userID: Auth.auth().currentUser?.uid ?? "")
                } else {
                    LogInView()
                }
            }
            .tabItem {
                Image(systemName: "person.crop.circle")
                Text("Profile")
            }
            .tag(TabItem.profile)

            Group {
                if FirebaseViewModel.shared.isLoggedIn {
                    CreateViewWrapper()
                } else {
                    SignUpView()
                }
            }
            .tabItem {
                Image(systemName: "plus")
                Text("Post")
            }
            .tag(TabItem.post)
        }
        .onAppear {
            selectedTab = .home
        }
    }

    struct HomeViewWrapper: View {
        var body: some View {
            NavigationStack {
                HomeView()
            }
        }
    }

    struct UserViewWrapper: View {
        var userID: String
        
        @State private var username: String = ""

        var body: some View {
            NavigationStack {
                UserView(userID: userID, username: username)
                    .onAppear {
                        FirebaseViewModel.shared.fetchUsername(userID: userID) { fetchedUsername in
                            username = fetchedUsername
                        }
                    }
            }
        }
    }
        
    struct CreateViewWrapper: View {
        var body: some View {
            NavigationStack {
                CreateView()
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
    // MARK: - AuthView
    struct LogInView: View {
        
        @State private var email: String = ""
        @State private var password: String = ""
        @State private var authSuccessMessage = ""
        @State private var authFailureMessage = ""
        @State private var showSuccessAlert = false
        
        var body: some View {
            
            NavigationStack {
                
                VStack {
                    
                    Text("Authentication")
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .frame(width: 250.0, height: 100.0)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .frame(width: 250.0, height: 100.0)
                    
                    VStack {
                        Button(action: {
                            FirebaseViewModel.shared.login(email: email, password: password) { success, message in
                                if success {
                                    print("enter success logic")
                                    authSuccessMessage = message
                                    showSuccessAlert = true
                                    FirebaseViewModel.shared.isLoggedIn = true
                                    email = ""
                                    password = ""
                                } else {
                                    authFailureMessage = message
                                }
                            }
                        }) {
                            Text("Log in →")
                        }
                        
                        .actionSheet(isPresented: $showSuccessAlert) {
                            ActionSheet(
                                title: Text("Successfully Logged In!"),
                                buttons: [
                                    .default(Text("OK")) {}
                                ]
                            )
                        }
                        
                        Text(authFailureMessage)
                            .padding(.top, 3)
                            .foregroundColor(Color.red)
                        
                        NavigationLink(destination: SignUpView()) {
                            Text("Create an account?")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        
    }
    
    struct SignUpView: View {
        @State private var showingSuccessAlert = false
        @State private var showingTermsSheet = false
        @State private var email = ""
        @State private var password = ""
        @State private var username = ""
        @State private var failureMessage = ""

        var body: some View {
            NavigationStack {
                VStack {
                    Text("Registration")

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .frame(width: 260.0, height: 100.0)

                    SecureField("Password", text: $password)
                        .padding()
                        .frame(width: 260.0, height: 100.0)

                    TextField("Username", text: $username)
                        .padding()
                        .frame(width: 260.0, height: 100.0)

                    Button(action: {
                        showingTermsSheet = true
                    }) {
                        Text("Sign up →")
                    }
                    .sheet(isPresented: $showingTermsSheet) {
                        TermsSheetView { didAgree in
                            if didAgree {
                                FirebaseViewModel.shared.signUp(email: email, password: password, username: username) { success, message in
                                    if success {
                                        showingSuccessAlert = true
                                        FirebaseViewModel.shared.isLoggedIn = true
                                        email = ""
                                        password = ""
                                        username = ""
                                    } else {
                                        failureMessage = message
                                    }
                                }
                            }
                        }
                    }
                    .actionSheet(isPresented: $showingSuccessAlert) {
                        ActionSheet(
                            title: Text("Successfully Signed Up!"),
                            buttons: [
                                .default(Text("OK")) {}
                            ]
                        )
                    }

                    Text(failureMessage)
                        .padding(.top, 3)
                        .foregroundColor(Color.red)

                    NavigationLink(destination: LogInView()) {
                        Text("Already have our account?")
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }


}

// MARK: - ContentView END

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
    var videoURL: String
    var thumbnailURL: URL?
    var caption: String?
    var timestamp: Timestamp?
    var creationDate: Date?
    var fileType: String
    var username: String
    var views: Int = 0
}

struct User: Identifiable {
    var id: String
    var profileImageURL: URL
    var username: String
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

struct SpatialVideoPlayer: UIViewControllerRepresentable {
    var videoURL: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = AVPlayer(url: videoURL)
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if uiViewController.player?.currentItem?.asset != AVAsset(url: videoURL) {
            uiViewController.player = AVPlayer(url: videoURL)
            uiViewController.player?.play()
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
            
            NavigationLink(destination: CreateView()) {
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
