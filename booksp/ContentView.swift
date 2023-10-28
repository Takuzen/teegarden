//
//  ContentView.swift
//  booksp
//
//  Created by Takuzen Toh on 7/5/23.
//

import SwiftUI
import FirebaseAuth
import RealityKit
import RealityKitContent

import Observation
import Foundation
import SwiftyJSON

struct Book {
    let id: String
    let volumeInfo:JSON
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
//                title: item["volumeInfo"]["title"].stringValue
//                descryption: item["volumeInfo"]["description"].stringValue,
//                thumbnail: item["volumeInfo"]["imageLinks"]["thumbnail"].stringValue
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

struct ContentView: View {

    @State var showImmersiveSpace = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    @EnvironmentObject var viewModel: FirebaseViewModel
    @ObservedObject var googleBooksAPI = GoogleBooksAPIRepository()
    
    var body: some View {
        NavigationSplitView {
            if viewModel.isLoggedIn {
                loggedInView
            } else {
                loggedOutView
            }
        } detail: {
            VStack {
                Model3D(named: "Scene", bundle: realityKitContentBundle)
                    .padding(.bottom, 50)

                Text("Welcome to BookSP!")

                Toggle("My Space", isOn: $showImmersiveSpace)
                    .toggleStyle(.button)
                    .padding(.top, 50)
            }
            .navigationTitle("Content")
            .padding()
        }
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                if newValue {
                    await openImmersiveSpace(id: "ImmersiveSpace")
                } else {
                    await dismissImmersiveSpace()
                }
            }
        }
    }
    
    private var loggedInView: some View {
        VStack {
            TextField("検索ボックス", text: $googleBooksAPI.query)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onSubmit {
                    Task {
                        await googleBooksAPI.getBooks()
                    }
                }
            
            if(googleBooksAPI.booksResult.count>0){
                ForEach(0 ..< googleBooksAPI.booksResult.count) { index in
                    Text("Result: \(googleBooksAPI.booksResult[index].volumeInfo["title"].stringValue)")
                        .onTapGesture {
                            debugPrint("debug")
                            debugPrint(googleBooksAPI.booksResult[index].id)
                            debugPrint(googleBooksAPI.booksResult[index].volumeInfo["imageLinks"]["thumbnail"])
                            viewModel.createFavoriteBook(
                                bookId: googleBooksAPI.booksResult[index].id,
                                thumnailUrl: googleBooksAPI.booksResult[index].volumeInfo["imageLinks"]["thumbnail"].stringValue
                            )
                        }
                }
            }
            
            Button(action: {
                viewModel.signOut()
            }) {
                Text("Sign Out")
            }
        }.onAppear{
            debugPrint(viewModel.favoriteBooks.count)
            viewModel.getFavoriteBooks()
            debugPrint(viewModel.favoriteBooks.count)
        }
    }
    
    private var loggedOutView: some View {
        VStack {
            TextField("Email", text: $viewModel.mail)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .frame(width : 250.0, height : 100.0)
            
            SecureField("Password", text: $viewModel.password)
                .padding()
                .frame(width : 250.0, height : 100.0)
            
            Text(viewModel.errorMessage)
        
            HStack{
                Button(action: {
                    viewModel.signUp()
                }) {
                    Text("Sign Up")
                }
                
                Button(action: {
                    viewModel.login()
                }) {
                    Text("Log In")
                }
            }
        }
    }

}

#Preview {
    ContentView()
}
