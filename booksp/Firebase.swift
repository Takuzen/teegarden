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
    @Published var mail: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var favoriteBooks: [Book] = [] // Add this line
    
    struct Book: Identifiable {
        let id: String
        let title: String
        let author: String
        let year: Int
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
        } catch let signOutError as NSError {
            self.errorMessage = "Error signing out: \(signOutError.localizedDescription)"
        }
    }
    
    // Create a book
    func createFavoriteBook(bookId: String) {
        var db = Firestore.firestore()
        guard let user = Auth.auth().currentUser else { return }
        
        db.collection("users").document(user.uid).collection("favorites").document(bookId).setData(["timestamp": FieldValue.serverTimestamp()]) { error in
            if let error = error {
                self.errorMessage = "Error adding favorite book: \(error)"
            } else {
                self.errorMessage = "Favorite book added successfully!"
                self.getFavoriteBooks()
            }
        }
    }
    
    // Get books
    func getFavoriteBooks() {
        guard let user = Auth.auth().currentUser else { return }
        var db = Firestore.firestore()
        db.collection("users").document(user.uid).collection("favorites").getDocuments { querySnapshot, error in
            if let error = error {
                self.errorMessage = "Error getting books: \(error)"
            } else {
                self.favoriteBooks = querySnapshot?.documents.compactMap { document in
                    let data = document.data()
                    if let title = data["title"] as? String,
                       let author = data["author"] as? String,
                       let year = data["year"] as? Int {
                        return Book(id: document.documentID, title: title, author: author, year: year)
                    } else {
                        return nil
                    }
                } ?? []
            }
        }
    }
    
    // Delete a book
    func deleteBook(bookId: String) {
        guard let user = Auth.auth().currentUser else { return }
        var db = Firestore.firestore()
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
