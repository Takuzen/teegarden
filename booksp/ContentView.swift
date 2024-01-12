import SwiftUI
import UniformTypeIdentifiers
import FirebaseAuth
import RealityKit

import Observation
import Foundation
import SwiftyJSON

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
    
    func addPost(_ post: Post) {
        posts.insert(post, at: 0)
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
            debugPrint(result.prefix(5))
            DispatchQueue.main.async {
                self.booksResult = result
            }
        }
        
        public func getBookById(bookId:String) async {
            let data = try! await downloadData(urlString: "\(endpoint)/volumes/\(query)")
            let json = JSON(data)
            let result = await self.setVolume(json)
            debugPrint(result.prefix(5))
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
    debugPrint(i)
    if(!i.hasPrefix("http")){return ""}
    let insertIdx = i.index(i.startIndex, offsetBy: 4)
    i.insert(contentsOf: "s", at: insertIdx)
    return i
}
    
struct ContentView: View {
    
    @State var showImmersiveSpace_Progressive = false
    @State private var defaultSelectionForHomeMenu: String? = "Home"
    @State private var defaultSelectionForUserMenu: String? = "All"
    
    @StateObject var feedModel = FeedModel()
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @EnvironmentObject var viewModel: FirebaseViewModel
    
    @ObservedObject var googleBooksAPI = GoogleBooksAPIRepository()
    
    let homeMenuItems = ["Home"]
    let userMenuItems = ["All"]
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: CGFloat(10), alignment: nil),
        GridItem(.flexible(), spacing: CGFloat(10), alignment: nil),
        GridItem(.flexible(), spacing: CGFloat(10), alignment: nil),
    ]
    
    var body: some View {
        NavigationSplitView {
            VStack {
                if showImmersiveSpace_Progressive {
                    List(userMenuItems, id: \.self, selection: $defaultSelectionForUserMenu) { item in
                        NavigationLink(destination: userAllView) {
                            HStack {
                                Image(systemName: "house")
                                Text(item)
                            }
                        }
                    }
                } else {
                    List(userMenuItems, id: \.self, selection: $defaultSelectionForUserMenu) { item in
                        NavigationLink(destination: homeView().environmentObject(feedModel)) {
                            HStack {
                                Image(systemName: "infinity")
                                Text(item)
                            }
                        }
                    }
                }
                Toggle("My Space →", isOn: $showImmersiveSpace_Progressive)
                    .toggleStyle(.button)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Menu")
        } detail: {
            if showImmersiveSpace_Progressive {
                userAllView
            } else {
                homeView().environmentObject(feedModel)
            }
        }
        .environmentObject(feedModel)
        .onChange(of: showImmersiveSpace_Progressive) { _, newValue in
            Task {
                if newValue {
                    await openImmersiveSpace(id: "ImmersiveSpace_Progressive")
                } else {
                    await dismissImmersiveSpace()
                }
            }
        }
    }
}

struct BottomView: View {
    var body: some View {
        HStack {
            Button(action: {
                NavigationLink("") {
                    CategorySelectionView()
                }
            }, label: {
                Label("Add Content", systemImage: "plus")
            })
        }
        .padding()
    }
}

struct homeView: View {
    @EnvironmentObject var feedModel: FeedModel

    var body: some View {
        ScrollView {
            ForEach(feedModel.posts, id: \.id) { post in
                HStack {
                    Text(post.caption)
                    Model3D(url: post.modelURL) { model in
                                            model
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 100, height: 100)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                        .padding()
                }
                .padding()
            }
        }
    }
}

struct userViewOrnament: View {
    var body: some View {
        HStack {
            Label("Add Content", systemImage: "plus")
            Label("Support", systemImage: "questionmark")
        }
    }
}
    
private var userAllView: some View {
    NavigationStack {
        VStack {
            Text("Let's learn how to build your spatial contents!")
                .padding()
            NavigationLink(destination: CategorySelectionView()) {
                Text("Demo →")
                    .padding()
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
            }
        }
    }
    .ornament(attachmentAnchor: .scene(.bottom)) {
        BottomView().glassBackgroundEffect(in: .capsule)
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
    
struct Add3DModelView: View {
    @State private var isPickerPresented = false
    @State private var selectedModelURL: URL? = nil
    @State private var captionText: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoadingModel = false
    @EnvironmentObject var feedModel: FeedModel
    
    private let sample_3dmodelurl = URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/teapot/teapot.usdz")!
    
    var body: some View {
        NavigationStack {
            VStack {
                Button("Choose 3D Model") {
                    isPickerPresented = true
                    print("File picker presented")
                }
                .fileImporter(
                    isPresented: $isPickerPresented,
                    allowedContentTypes: [UTType.usdz],
                    allowsMultipleSelection: false
                ) { result in
                    print("File picker result received")
                    switch result {
                    case .success(let urls):
                        print("Model URL selected: \(String(describing: urls.first))")
                        isLoadingModel = true
                        self.selectedModelURL = urls.first
                    case .failure(let error):
                        print("Error selecting file: \(error.localizedDescription)")
                        alertMessage = "Error selecting file: \(error.localizedDescription)"
                        showAlert = true
                    }
                }

                if let modelURL = selectedModelURL {
                    Model3D(url: modelURL) { model in
                        model
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                    } placeholder: {
                        if isLoadingModel {
                            ProgressView()
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { // 5 seconds timeout
                                        if isLoadingModel {
                                            alertMessage = "Loading timeout. Please try a different model."
                                            showAlert = true
                                            isLoadingModel = false
                                        }
                                    }
                                }
                        }
                    }
                } else {
                    Text("No model selected").padding()
                }
                
                TextField("Write a caption...", text: $captionText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button("Post →") {
                        if let modelURL = selectedModelURL {
                            let newPost = Post(modelURL: modelURL, caption: captionText)
                            feedModel.addPost(newPost)
                            alertMessage = "Your post has been successfully added!"
                            showAlert = true
                            captionText = ""
                            selectedModelURL = nil
                        } else {
                            alertMessage = "Please select a model first"
                            showAlert = true
                        }
                    }
                    .padding()
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Notification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                    }
                }
            }
            .padding()
        }
    }
}

/*
 private var logInView: some View {
         VStack {
         TextField("Email", text: $viewModel.mail)
         .keyboardType(.emailAddress)
         .autocapitalization(.none)
         .padding()
         .frame(width: 250.0, height: 100.0)
         
         SecureField("Password", text: $viewModel.password)
         .padding()
         .frame(width: 250.0, height: 100.0)
         
         Text(viewModel.errorMessage)
         
         VStack {
         Button(action: {
         viewModel.login()
         }) {
         Text("Authenticate →")
         }
         
         Text("Create an account?")
         .foregroundColor(.black)
         .onTapGesture {
         viewModel.signUp()
         }
         }
         }
         }
 */

/*
 #Preview {
 ContentView()
 }
 */
