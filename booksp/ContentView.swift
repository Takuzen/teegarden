import SwiftUI
import UniformTypeIdentifiers
import FirebaseAuth
import RealityKit
import RealityKitContent

import Observation
import Foundation
import SwiftyJSON

struct Book {
    let id: String
    let volumeInfo: JSON
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
                    volumeInfo: item["volumeInfo"]
    //              title: item["volumeInfo"]["title"].stringValue
    //              descryption: item["volumeInfo"]["description"].stringValue,
    //              thumbnail: item["volumeInfo"]["imageLinks"]["thumbnail"].stringValue
                )
                books.append(bk)
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
                                                .frame(width: 200, height: 200)
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
            NavigationLink(destination: BookSelectionView()) {
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
    
struct BookSelectionView: View {
    var body: some View {
        Text("Book Selection")
    }
}
    
struct Add3DModelView: View {
    @State private var isPickerPresented = false
    @State private var selectedModelURL: URL? = nil
    @State private var captionText: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @EnvironmentObject var feedModel: FeedModel
    
    private let sample_3dmodelurl = URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/teapot/teapot.usdz")!
    
    var body: some View {
        NavigationStack {
            VStack {
                Button("Choose 3D Model") {
                                    isPickerPresented = true
                                }
                                .fileImporter(
                                    isPresented: $isPickerPresented,
                                    allowedContentTypes: [UTType.usdz],
                                    allowsMultipleSelection: false
                                ) { result in
                                    switch result {
                                    case .success(let urls):
                                        self.selectedModelURL = urls.first
                                    case .failure(let error):
                                        print("Error selecting file: \(error.localizedDescription)")
                                    }
                                }
                                
                                if let url = selectedModelURL {
                                    Model3D(url: url) { model in
                                        model
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 200, height: 200)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                } else {
                                    Text("No model selected")
                                    .padding()
                                }
                
                TextField("Write a caption...", text: $captionText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Spacer()
                
                HStack {
                    Spacer()
                    Button("Post →") {
                        let newPost = Post(modelURL: sample_3dmodelurl, caption: captionText)
                        feedModel.addPost(newPost)
                        alertMessage = "Your post has been successfully added!"
                        showAlert = true
                        captionText = ""
                    }
                    .padding()
                    .alert(isPresented: $showAlert) {
                        Alert(title: Text("Post Successful"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
