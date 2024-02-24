import SwiftUI
import UIKit
import QuickLook

import UniformTypeIdentifiers
extension UTType {
    static let reality = UTType(exportedAs: "com.apple.reality")
}

import Firebase

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
                    Add3DModelViewWrapper()
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
                                    FirebaseViewModel.shared.mail = ""
                                    FirebaseViewModel.shared.password = ""
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
        @EnvironmentObject var firebase: FirebaseViewModel
        @State private var showingSuccessAlert = false
        @State private var successMessage = "User registration has succeeded!"
        @State private var navigateToUserHome = false

        var body: some View {
            NavigationStack {
                VStack {
                    Text("Registration")
                    
                    TextField("Email", text: $firebase.mail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .frame(width: 260.0, height: 100.0)
                    
                    SecureField("Password", text: $firebase.password)
                        .padding()
                        .frame(width: 260.0, height: 100.0)
                    
                    TextField("Username", text: $firebase.username)
                        .padding()
                        .frame(width: 260.0, height: 100.0)
                    
                    Button(action: {
                        firebase.signUp(username: firebase.username) { success, message in
                            if success {
                                successMessage = message
                                showingSuccessAlert = true
                                firebase.isLoggedIn = true
                            } else {
                                firebase.errorMessage = message
                            }
                        }
                    }) {
                        Text("Sign up →")
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

struct DetailView: View {
    let userID: String
    let postID: String
    
    @State private var post: Post?
    @State private var showSpatialPlayer = false
    @State private var profileImageURL: URL?
    
    var body: some View {
        VStack {
            if let post = post {
                NavigationLink(destination: UserView(userID: userID, username: post.username)) {
                    HStack {
                        if let profileImageURL = profileImageURL {
                            AsyncImage(url: profileImageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                case .failure(_):
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }
                        Text(post.username)
                            .bold()
                            .padding(.leading, 5)
                        Spacer()
                    }
                    .padding(.bottom, 25)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 800)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        if post.fileType == "mov" {
                            Button(action: {
                                self.showSpatialPlayer = true
                            }) {
                                ZStack {
                                    AsyncImage(url: post.thumbnailURL) { image in
                                        image.resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 800, height: 500)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } placeholder: {
                                        Color.gray
                                            .frame(width: 800, height: 500)
                                    }
                                    Image(systemName: "play.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                }
                            }
                            .sheet(isPresented: $showSpatialPlayer) {
                                SpatialVideoPlayer(videoURL: URL(string: post.videoURL)!)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            USDZQLPreview(url: URL(string: post.videoURL)!)
                                .frame(width: 800, height: 500)
                        }
                        Text(post.caption ?? "")
                            .frame(width: 800, alignment: .leading)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                    }
                }
            } else {
                Text("Post details not found.")
            }
        }
        .onAppear {
            fetchProfileImage(for: userID)
            getPostDocument(userID: userID, postID: postID)
        }
    }
    
    private func fetchProfileImage(for userID: String) {
        FirebaseViewModel.shared.fetchProfileImageURL(for: userID) { url in
            profileImageURL = url
        }
    }
    
    private func getPostDocument(userID: String, postID: String) {
        let db = Firestore.firestore()
        let postRef = db.collection("users").document(userID).collection("posts").document(postID)
        
        postRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let thumbnailURL = (data?["thumbnailURL"] as? String).flatMap(URL.init)
                let videoURL = data?["videoURL"] as? String ?? ""
                let caption = data?["caption"] as? String
                let fileType = data?["fileType"] as? String ?? ""
                let username = data?["username"] as? String ?? "Unknown"
                
                post = Post(id: postID, creatorUserID: userID, videoURL: videoURL, thumbnailURL: thumbnailURL, caption: caption, creationDate: nil, fileType: fileType, username: username)
            }
        }
    }
}

/*
struct DetailViewFromProfile: View {
    let postID: String
    let userID: String
    let username: String
    let thumbnailURL: URL?
    let localFileURL: URL
    let caption: String
    
    @ObservedObject var firebaseViewModel: FirebaseViewModel
    
    @State private var showSpatialPlayer = false
    @State private var profileImageURL: URL?
    
    func fetchProfileImage(for userID: String) {
        firebaseViewModel.fetchProfileImageURL(for: userID) { url in
            if let url = url {
                withAnimation {
                    profileImageURL = url
                }
            }
        }
    }
    
    var body: some View {
        
        VStack {
            
            NavigationLink(destination: UserView(userID: userID, username: username)) {
                HStack {
                    if let profileImageURL = profileImageURL {
                        AsyncImage(url: profileImageURL) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            case .failure(_):
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                            case .empty:
                                ProgressView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    }
                    
                    Text(username)
                        .bold()
                        .padding(.leading, 5)
                    
                    Spacer()
                }
                .padding(.bottom, 25)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 800)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    if let post = firebaseViewModel.userPosts.first(where: { $0.id == postID }) {

                        if post.fileType == "mov" {
                            Button(action: {
                                self.showSpatialPlayer = true
                            }) {
                                ZStack {

                                    AsyncImage(url: thumbnailURL) { image in
                                        image.resizable()
                                             .aspectRatio(contentMode: .fill)
                                             .frame(width: 800, height: 500)
                                             .clipped()
                                             .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } placeholder: {
                                        Color.gray
                                            .frame(width: 800, height: 500)
                                    }

                                    Image(systemName: "play.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                }
                            }
                            .sheet(isPresented: $showSpatialPlayer) {
                                SpatialVideoPlayer(videoURL: localFileURL)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                        } else {

                            USDZQLPreview(url: localFileURL)
                                .frame(width: 800, height: 500)
                            
                        }
                        
                    } else {
                        
                        Text("Post details not found.")
                        
                    }
                    
                    Text(caption)
                        .frame(width: 800, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    
                }
            }
            .onAppear {
                fetchProfileImage(for: userID)
            }
        }
    }
}
 */

/*
struct homeView: View {

    @State private var localFileURLs: [String: URL] = [:]
    @State private var fileURLs: [URL] = []
    @State private var profileImageURLs: [String: URL] = [:]
    
    func fetchProfileImage(for userID: String) {
        FirebaseViewModel.shared.fetchProfileImageURL(for: userID) { url in
            if let url = url {
                withAnimation {
                    profileImageURLs[userID] = url
                }
            }
        }
    }
    
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
                .padding(.leading, 15)
                .padding(.top, 40)
                
                VStack {
                    HStack {
                        Text("Spatial Creators")
                            .font(.headline)
                            .padding(.leading)
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.leading, 10)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        let rows = [GridItem(.flexible(minimum: 10, maximum: .infinity), spacing: 20)]
                        
                        LazyHGrid(rows: rows, spacing: 20) {
                            
                            ForEach(FirebaseViewModel.shared.homePosts) { post in
                                
                                NavigationLink(destination: DetailView(userID: post.creatorUserID, postID: post.id)) {
                                    
                                    VStack {
                                        
                                        NavigationLink(destination: UserView(userID: post.creatorUserID, username: post.username)) {
                                            HStack {
                                                if let profileImageURL = profileImageURLs[post.creatorUserID] {
                                                    AsyncImage(url: profileImageURL) { phase in
                                                        switch phase {
                                                        case .success(let image):
                                                            image.resizable()
                                                                .aspectRatio(contentMode: .fill)
                                                                .frame(width: 40, height: 40)
                                                                .clipShape(Circle())
                                                        case .failure(_):
                                                            Image(systemName: "person.crop.circle.fill")
                                                                .resizable()
                                                                .frame(width: 30, height: 30)
                                                                .clipShape(Circle())
                                                        case .empty:
                                                            ProgressView()
                                                        @unknown default:
                                                            EmptyView()
                                                        }
                                                    }
                                                    
                                                } else {
                                                    
                                                    Image(systemName: "person.crop.circle.fill")
                                                        .resizable()
                                                        .frame(width: 30, height: 30)
                                                        .clipShape(Circle())
                                                }
                                                
                                                Text(post.username)
                                                    .bold()
                                                    .padding(.leading, 5)
                                                
                                                Spacer()
                                            }
                                            .padding(.bottom, 25)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .frame(width: 600)
                                        
                                        switch post.fileType {
                                        case "mov":
                                            if let thumbnailURL = post.thumbnailURL {
                                                ZStack(alignment: .topTrailing) {
                                                    AsyncImage(url: thumbnailURL) { phase in
                                                        switch phase {
                                                        case .success(let image):
                                                            image.resizable()
                                                                .scaledToFill()
                                                                .frame(width: 600, height: 247.22)
                                                                .clipped()
                                                                .transition(.opacity)
                                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                        case .failure(_), .empty:
                                                            EmptyView()
                                                        @unknown default:
                                                            EmptyView()
                                                        }
                                                    }
                                                    .padding(.top, 5)
                                                    .padding(.trailing, 5)
                                                    
                                                    Image(systemName: "pano.badge.play.fill")
                                                        .symbolRenderingMode(.palette)
                                                        .imageScale(.large)
                                                        .padding([.top, .trailing], 20)
                                                }
                                            } else {
                                                
                                                Text("No thumbnail available")
                                                    .frame(width: 600, height: 247.22)
                                                    .background(Color.gray.opacity(0.5))
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    .shadow(radius: 10)
                                                    .padding(.top, 30)
                                                    .padding(.bottom, 30)
                                                
                                            }
                                        case "usdz", "reality":
                                            ZStack(alignment: .topTrailing) {
                                                
                                                Model3D(url: URL(string: post.videoURL)!) { model in
                                                    model
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                } placeholder: {
                                                    ProgressView()
                                                }
                                                .frame(width: 540, height: 187.22)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .padding(.top, 55)
                                                .padding(.bottom, 55)
                                                
                                                Image(systemName: "move.3d")
                                                    .symbolRenderingMode(.palette)
                                                    .imageScale(.large)
                                                    .padding([.top, .trailing], 20)
                                                
                                            }
                                        default:
                                            Text("Unsupported or no preview available")
                                                .frame(width: 600, height: 247.22)
                                                .background(Color.gray.opacity(0.5))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        
                                        if let caption = post.caption, !caption.isEmpty {
                                            Text(caption)
                                                .lineLimit(3)
                                                .truncationMode(.tail)
                                                .frame(maxWidth: 500, alignment: .leading)
                                                .padding(.top, 20)
                                        }

                                    }
                                    .onAppear {
                                                // Debug statement to print post details
                                                print("Post ID: \(post.id), Username: \(post.username), Caption: \(post.caption ?? "No caption")")
                                            }
                                }
                                .frame(width: 600, height: 800)
                                .buttonStyle(PlainButtonStyle())
                                /*
                                
                                 */
                            }
                            
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        .frame(height: geometry.size.height / 1.5)
                        
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height / 3 * 2 + 100)
                    .padding(.leading, 30)
                    .padding(.top, -30)
                    
                }
                Spacer()
                    .onAppear {
                        print("Fetching posts...")
                        FirebaseViewModel.shared.fetchHomePosts {
                            print("Posts fetched: \(FirebaseViewModel.shared.homePosts.count)")
                            for post in FirebaseViewModel.shared.homePosts {
                                print("Post ID: \(post.id), Username: \(post.username)")
                                fetchProfileImage(for: post.creatorUserID)
                            }
                            print("Posts: \(FirebaseViewModel.shared.homePosts)")
                        }
                    }
            }
        }
    }
}
 */

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
    var creationDate: Date?
    var fileType: String
    var username: String
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
        controller.player?.play()
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

class AlertViewModel: ObservableObject {
    @Published var showOverwriteAlert: Bool = false
    @Published var alertMessage: String = ""
    // Other alert-related states can be added here
}



// MARK: - Add3DModelView
struct Add3DModelView: View {
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
        
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: firstModelURL.path)
            if let fileSize = fileAttributes[.size] as? NSNumber, fileSize.intValue <= 104857600 {
                // File size is within the limit, proceed with the rest of the function
            } else {
                // File size exceeds the limit, show an alert
                DispatchQueue.main.async {
                    self.isFileSizeLimitExceeded = true // Set the state variable to show the alert
                }
                return
            }
        } catch {
            // Error while getting file attributes, show an alert
            DispatchQueue.main.async {
                self.showAlertWith(message: "Failed to get file attributes.")
            }
            return
        }

        let canAccess = firstModelURL.startAccessingSecurityScopedResource()
        print("Can access firstModelURL: \(canAccess)")
        
        if canAccess {
            switch firstModelURL.pathExtension.lowercased() {
            case "mov":
                print("Handling a .mov file")
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
            case "usdz", "reality":
                print("Handling a .usdz or .reality file")
                // For usdz and reality files, directly process the model without a thumbnail
                self.processModel(thumbnailURL: nil, originalURL: firstModelURL, shouldOverwrite: shouldOverwrite)
            default:
                print("Unsupported file type.")
                DispatchQueue.main.async {
                    self.showAlertWith(message: "Unsupported file type.")
                }
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
                        
                        Text("We accept uploading a spatial video and model.")
                            .padding(.top, 5)
                        
                        Text("MOV/MV-HEVC, USDZ, or REALITY File are welcomed.")
                        
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
        .alert(isPresented: $isPostingSuccessful) {
            Alert(
                
                title: Text("Posting was successful!"),
                
                dismissButton: .default(Text("OK")) {
                    
                    confirmedModelURL = nil
                    
                    captionText = ""
                }
            )
        }
        
        .alert(isPresented: $isFileSizeLimitExceeded) {
            Alert(
                title: Text("File Size Limit Exceeded"),
                message: Text("The selected file exceeds the 100MB limit. Please choose a smaller file."),
                dismissButton: .default(Text("OK")) {
                }
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
