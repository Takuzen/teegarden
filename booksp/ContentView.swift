import SwiftUI
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
                        NavigationLink(destination: viewForUserHome(item)) {
                            HStack {
                                Image(systemName: "house")
                                Text(item)
                            }
                        }
                    }
                } else {
                    List(userMenuItems, id: \.self, selection: $defaultSelectionForUserMenu) { item in
                        NavigationLink(destination: viewForRootHome(item)) {
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
                homeView
            }
        }
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
    
    @ViewBuilder
    private func viewForRootHome(_ item: String) -> some View {
        switch item {
        case "Home":
            homeView
        default:
            EmptyView()
        }
    }
    
    private var homeView: some View {
        Text("Posts in latest order")
    }
    
    @ViewBuilder
    private func viewForUserHome(_ item: String) -> some View {
        switch item {
        case "All":
            userAllView
        default:
            EmptyView()
        }
    }
    
    private var userAllView: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                NavigationLink(destination: CategorySelectionView()) {
                    HStack {
                        Text("Add")
                            .padding()
                            .foregroundColor(Color.white)
                            .cornerRadius(2)
                        Image(systemName: "plus")
                    }
                }
            }
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
        var body: some View {
            Text("Add 3D Model")
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
