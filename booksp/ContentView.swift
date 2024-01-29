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
                        logInViewToProfile()
                            .environmentObject(firebase)
                    } else if tab == .profile && firebase.isLoggedIn {
                        UserAllViewWrapper()
                    } else if tab == .post && !firebase.isLoggedIn {
                        logInViewToPost()
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
    // MARK: - LogInView
    struct logInViewToProfile: View {
        
        @EnvironmentObject var firebase: FirebaseViewModel
        
        @State private var showingSuccessAlert = false
        @State private var successMessage = "Signed In Successfully."
        @State private var navigationTag: NavigationTag?
        
        enum NavigationTag {
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
                                navigationTag = .userAllView
                            }
                        } message: { successMessage in
                            Text(successMessage)
                        }
                        
                        Text(firebase.errorMessage)
                        
                        Text("Create an account?")
                            .onTapGesture {
                                
                            }
                        
                        NavigationLink(value: NavigationTag.userAllView) {
                            EmptyView()
                        }
                        .hidden()
                    }
                }
                .navigationDestination(for: NavigationTag.self) { tag in
                    switch tag {
                    case .userAllView:
                        UserAllViewWrapper()
                    }
                }
            }
        }
    }
    
    struct logInViewToPost: View {
        
        @EnvironmentObject var firebase: FirebaseViewModel
        
        @State private var showingSuccessAlert = false
        @State private var successMessage = "Signed In Successfully."
        @State private var navigationTag: NavigationTag?
        
        enum NavigationTag {
            case postView
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
                                navigationTag = .postView
                            }
                        } message: { successMessage in
                            Text(successMessage)
                        }
                        
                        Text(firebase.errorMessage)
                        
                        Text("Create an account?")
                            .onTapGesture {
                                
                            }
                        
                        NavigationLink(value: NavigationTag.postView) {
                            EmptyView()
                        }
                        .hidden()
                    }
                }
                .navigationDestination(for: NavigationTag.self) { tag in
                    switch tag {
                    case .postView:
                        Add3DModelViewWrapper()
                    }
                }
            }
        }
    }
    
    struct SignUpView: View {
        
        @EnvironmentObject var firebase: FirebaseViewModel
        
        @State private var showingSuccessAlert = false
        @State private var successMessage = "User registration has succeeded!."
        @State private var navigationTag: NavigationTag?
        
        enum NavigationTag {
            case userAllView
        }
        
        var body: some View {
            VStack {
                Text("Registration")
                
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
                        firebase.signUp { success, message in
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
                            navigationTag = .userAllView
                        }
                    } message: { successMessage in
                        Text(successMessage)
                    }
                    
                    Text(firebase.errorMessage)
                    
                    Text("Already have an account?")
                        .onTapGesture {
                            
                        }
                }
            }
            .navigationDestination(for: NavigationTag.self) { tag in
                switch tag {
                case .userAllView:
                    UserAllViewWrapper()
                }
            }
        }
    }
    
}

struct homeView: View {
    @EnvironmentObject var feedModel: FeedModel
    
    var body: some View {
            VStack {
                
                HStack {
                    Image("teegarden-logo-nobg")
                        .resizable()
                        .frame(width: 30, height: 30)
                    Text("Teegarden")
                        .font(.system(size: 25))
                    Spacer()
                }
                
                VStack {
                    
                    HStack {
                        Text("Spatial Videos")
                            .font(.headline)
                            .padding(.leading)
                        Spacer()
                    }
                    
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack {
                            ForEach(feedModel.posts, id: \.id) { post in
                                VStack {
                                    HStack {
                                        Image(systemName:"person.crop.circle")
                                        Text("username")
                                    }
                                    Model3D(url: post.modelURL) { model in
                                        model
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 100)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .padding()
                                    Text(post.caption)
                                }
                                .padding()
                            }
                        }
                    }
                }
                
                VStack {
                    
                    HStack {
                        Text("Makers' Products")
                            .font(.headline)
                            .padding(.leading)
                        Spacer()
                    }
                    
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack {
                            ForEach(feedModel.posts, id: \.id) { post in
                                VStack {
                                    HStack {
                                        Image(systemName:"person.crop.circle")
                                        Text("username")
                                    }
                                    Model3D(url: post.modelURL) { model in
                                        model
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 100)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .padding()
                                    Text(post.caption)
                                }
                                .padding()
                            }
                        }
                    }
                }
            }
            .padding(.leading, 20)
    }
}
    
struct userAllView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Teegarden is the tool, designed to help makers broaden the range of expression by adding one more dimension. Moreover, for any people wish to have a spatial archive. Check out our guide book, raising your head.")
                    .padding()
                NavigationLink(destination: Add3DModelView()) {
                    Text("Go post now →")
                        .padding()
                        .foregroundColor(Color.white)
                        .cornerRadius(8)
                }
            }
        }
        .navigationTitle("My Space")
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
    var id = UUID()
    var modelURL: URL
    var caption: String
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

func saveModelToTemporaryFolder(modelURL: URL, overwrite: Bool) async -> Result<URL, Error> {
    
    let fileManager = FileManager.default
    
    // Get the documents directory URL
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    // Create a URL for the "TmpModelFiles" directory
    let tmpModelFilesDirectory = documentsDirectory.appendingPathComponent("TmpModelFiles")
    
    if !fileManager.fileExists(atPath: tmpModelFilesDirectory.path) {
        do {
            try fileManager.createDirectory(at: tmpModelFilesDirectory, withIntermediateDirectories: true)
        } catch {
            return .failure(error)
        }
    }
        
    // Define the destination URL for the model file
    let destinationURL = tmpModelFilesDirectory.appendingPathComponent(modelURL.lastPathComponent)
    
    // Check if the file already exists at the destination
    if fileManager.fileExists(atPath: destinationURL.path) {
        guard overwrite else {
            return .failure(FileSaveError.fileExists)
        }
        // If the user has agreed to overwrite, then delete the existing file first
        do {
            try fileManager.removeItem(at: destinationURL)
        } catch {
            return .failure(error)
        }
    }
        
    // Copy the file from the source URL to the destination
    do {
        try fileManager.copyItem(at: modelURL, to: destinationURL)
        return .success(destinationURL)
        
    } catch {
        return .failure(error)
    }
        
}

func loadModelsFromTemporaryFolder() -> [URL] {
    // Get the documents directory URL
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let tmpModelFilesDirectory = documentsDirectory.appendingPathComponent("TmpModelFiles")
    
    do {
        // Get the directory contents URLs (including subfolders URLs)
        let directoryContents = try FileManager.default.contentsOfDirectory(at: tmpModelFilesDirectory, includingPropertiesForKeys: nil)
        
        // Filter the directory contents for files with the 'usdz' file extension
        let allowedExtensions = ["usdz", "reality", "hevc"]
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
    @State private var savedModelURL: URL?
    @State private var captionText: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoadingModel = false
    @State private var isPreviewing = false
    @State private var showOverwriteAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    @EnvironmentObject var feedModel: FeedModel
    
    func handleModelSelection(urls: [URL]) {
        guard let firstModelURL = urls.first else { return }
        
        // Start accessing the security-scoped resource
        let canAccess = firstModelURL.startAccessingSecurityScopedResource()
        
        if canAccess {
            Task {
                // First, attempt to save the model without overwriting
                let result = await saveModelToTemporaryFolder(modelURL: firstModelURL, overwrite: false)
                
                switch result {
                case .success(let savedURL):
                    // Model saved successfully
                    self.savedModelURL = savedURL
                    isPreviewing = true
                case .failure(let error):
                    if let fileSaveError = error as? FileSaveError, fileSaveError == .fileExists {
                        // If the error is because the file exists, prepare to ask for overwrite confirmation
                        DispatchQueue.main.async {
                            showOverwriteAlert = true
                        }
                    } else {
                        // For all other errors, show an error alert
                        DispatchQueue.main.async {
                            alertMessage = error.localizedDescription
                            showAlert = true
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                alertMessage = "You don't have permission to access the file."
                showAlert = true
            }
        }
    }
    
    // MARK: - Posting Logic
    private func postModel(with confirmedURL: URL) {
        
        let fileType = confirmedURL.pathExtension
        
        isLoadingModel = true
        
        FirebaseViewModel.shared.uploadModel(confirmedURL, fileType: fileType) { result in
            isLoadingModel = false
            switch result {
                case .success(let storageURL):
                    let newPost = Post(modelURL: storageURL, caption: captionText)
                    feedModel.addPost(newPost) {
                        if $0 {
                            alertTitle = "Success"
                            alertMessage = "Your post has been successfully added!"
                        } else {
                            alertTitle = "Failure"
                            alertMessage = "Failed to add post. Please try again."
                        }
                        showAlert = true
                        captionText = ""
                        savedModelURL = nil
                        selectedModelURL = nil
                        confirmedModelURL = nil
                    }
                case .failure(let error):
                    alertTitle = "Failure"
                    alertMessage = "Error uploading model: \(error.localizedDescription)"
                    showAlert = true
            }
        }
    }
    
    
    struct ModelPreviewView: View {
        @Binding var modelURL: URL?
        @Binding var confirmedModelURL: URL?
        @Binding var isPreviewing: Bool
        
        var body: some View {
            VStack {
                if let url = modelURL {
                    NavigationView {
                        VStack {
                            
                            Button(action: { isPreviewing = false }) {
                                Label("", systemImage: "xmark")
                            }
                            
                            USDZQLPreview(url: url)
                                .edgesIgnoringSafeArea(.all)
                            
                            Button("Confirm") {
                                confirmedModelURL = modelURL
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
                    Text("Hello, no URL available")
                }
            }
        }
    }

    var body: some View {
        
        @State var isPostingSuccessful: Bool = false
        
        let allowedContentTypes: [UTType] = [.usdz, .reality, .movie]
        
        NavigationStack {
            if let modelURL = confirmedModelURL {
                VStack {
                    
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
                    
                    Button("Re-select") {
                        /// the logic to open file picker and let users choose another file
                    }
                    .padding()
                    
                    TextField("Write a caption...", text: $captionText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    if confirmedModelURL == nil {
                        Button("Post →") {}
                            .disabled(true)
                            .padding()
                    } else {
                        HStack {
                            Spacer()
                            Button("Post →") {
                                if let confirmedURL = confirmedModelURL {
                                    postModel(with: confirmedURL)
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
                        }
                        .padding()
                    }
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
                        allowedContentTypes: [.usdz, .reality, .movie],
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
                    
                    .sheet(isPresented: $isPreviewing) {
                        ModelPreviewView(modelURL: $savedModelURL, confirmedModelURL: $confirmedModelURL, isPreviewing: $isPreviewing)
                    }
                    
                    .alert(isPresented: $showErrorAlert) {
                        Alert(
                            title: Text("Error"),
                            message: Text(errorMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                    
                    .alert(isPresented: $showOverwriteAlert) {
                        Alert(
                            title: Text("File Already Exists"),
                            message: Text("A file with the same name already exists. Would you like to overwrite it?"),
                            primaryButton: .destructive(Text("Overwrite")) {
                                Task {
                                    let result = await saveModelToTemporaryFolder(modelURL: selectedModelURL!, overwrite: true)
                                    // Handle result of overwrite attempt
                                    switch result {
                                    case .success(let savedURL):
                                        self.savedModelURL = savedURL
                                        isPreviewing = true
                                    case .failure(let error):
                                        errorMessage = error.localizedDescription
                                        showErrorAlert = true
                                    }
                                }
                            },
                            secondaryButton: .cancel()
                        )
                    }
                    
                    TextField("Write a caption...", text: $captionText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    if confirmedModelURL == nil {
                        Button("Post →") {}
                            .disabled(true)
                    } else {
                        HStack {
                            Spacer()
                            Button("Post →") {
                                if let confirmedURL = confirmedModelURL {
                                    postModel(with: confirmedURL)
                                } else {
                                    alertMessage = "Please confirm the model before posting."
                                    showAlert = true
                                }
                            }
                            .padding()
                            .alert(isPresented: $showAlert) {
                                Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                            }
                        }
                        .padding()
                    }
                }
            }
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

struct CubeToggle: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    @State private var isShowingCube: Bool = false

    var body: some View {
        Toggle("View", isOn: $isShowingCube)
            .onChange(of: isShowingCube) { newValue in
                if newValue {
                    openWindow(id: "CubeModelWindow")
                } else {
                    dismissWindow(id: "CubeModelWindow")
                }
            }
            .toggleStyle(.button)
    }
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
