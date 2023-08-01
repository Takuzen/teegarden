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

struct ContentView: View {

    @State var showImmersiveSpace = false

    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    @ObservedObject var viewModel = FirebaseViewModel()
    
    var body: some View {
        NavigationSplitView {
            List {
                Text("Item")
            }
            .navigationTitle("Sidebar")
            
            if viewModel.isUserLoggedIn() {
                loggedInView
            } else {
                loggedOutView
            }
            
        } detail: {
            VStack {
                Model3D(named: "Scene", bundle: realityKitContentBundle)
                    .padding(.bottom, 50)

                Text("Welcome to BookSP!")

                Toggle("My Den", isOn: $showImmersiveSpace)
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
            Text("Your favorite books:")
            
            List(viewModel.favoriteBooks) { book in
                Text("\(book.title) by \(book.author) (\(book.year))")
            }
            
            Text(viewModel.errorMessage)
            
            Button(action: {
                // Log out when button is pressed
                viewModel.signOut()
            }) {
                Text("Sign Out")
            }
        }
    }
    
    private var loggedOutView: some View {
        VStack {
            TextField("Email", text: $viewModel.mail)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            SecureField("Password", text: $viewModel.password)
            
            Text(viewModel.errorMessage)
            
//            TextField("メールアドレスを入力してください",text: $mail)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
//                
//            SecureField("パスワードを入力してください",text:$password)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//                .padding()
        
            Button(action: {
                viewModel.signUp()
            }) {
                Text("Sign Up")
            }
            
            Button(action: {
                // Sign in when button is pressed
                viewModel.login()
            }) {
                Text("Log In")
            }
            
        }
    }

}

#Preview {
    ContentView()
}
