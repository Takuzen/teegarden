//
//  Firebase.swift
//  booksp
//
//  Created by Taku on 2023/07/29.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore

class FirebaseViewModel: ObservableObject {
    static let shared: FirebaseViewModel = .init()
    
    @Published var isLoggedIn:Bool = false
    @Published var mail: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var favoriteBooks: [Book] = [] // Add this line
    
    struct Book: Identifiable {
        let id: String
        let thumnailUrl: String
    }

    // Sign up function
    func signUp() {
        Auth.auth().createUser(withEmail: mail, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.errorMessage = "User created successfully"
            }
        }
    }

    // Login function
    func login() {
        Auth.auth().signIn(withEmail: mail, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.isLoggedIn = self.isUserLoggedIn()
                self.errorMessage = "User signed in successfully"
            }
        }
    }

    // Check if user is signed in
    func isUserLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }

    // Sign out function
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = self.isUserLoggedIn()
        } catch let signOutError as NSError {
            self.errorMessage = "Error signing out: \(signOutError.localizedDescription)"
        }
    }
    
    // Create a book
    func createFavoriteBook(bookId: String, thumnailUrl:String) {
        let db = Firestore.firestore()
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection("users").document(user.uid).collection("favorites").document(bookId).setData(["thumbnailUrl": thumnailUrl]) { error in
            if let error = error {
                self.errorMessage = "E: \(error)"
                debugPrint(error)
            } else {
                self.errorMessage = "Favorite book added successfully!"
                self.getFavoriteBooks()
            }
        }
    }
    
    // Get books
    func getFavoriteBooks() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("favorites").getDocuments { querySnapshot, error in
            if let error = error {
                self.errorMessage = "Error getting books: \(error)"
            } else {
                self.favoriteBooks = querySnapshot?.documents.compactMap { document in
                    debugPrint(document.documentID)
                    if let thumnailUrl = document.get("thumbnailUrl") as? String {
                        debugPrint("url is ")
                        debugPrint(thumnailUrl)
                        return Book(id: document.documentID, thumnailUrl:thumnailUrl)
                    } else {
                        return nil
                    }
                } ?? []
                debugPrint(self.favoriteBooks.count)
            }
        }
    }
    
    // Delete a book
    func deleteBook(bookId: String) {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("books").document(bookId).delete() { error in
            if let error = error {
                self.errorMessage = "Error deleting book: \(error)"
            } else {
                self.errorMessage = "Book deleted successfully!"
                self.getFavoriteBooks()
            }
        }
    }
}
