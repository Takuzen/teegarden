//
//  Firebase.swift
//  booksp
//
//  Created by Taku on 2023/07/29.
//

import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftyJSON

class FirebaseViewModel: ObservableObject {
    static let shared: FirebaseViewModel = .init()
    
    @Published var isLoggedIn:Bool = false
    @Published var mail: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var favoriteBooks: [Book] = []
    
    // Sign up function
    func signUp(completion: @escaping (Bool, String) -> Void) {
        Auth.auth().createUser(withEmail: mail, password: password) { authResult, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                self.errorMessage = "User created successfully"
            }
        }
    }

    // Login function
    func login(completion: @escaping (Bool, String) -> Void) {
        Auth.auth().signIn(withEmail: mail, password: password) { authResult, error in
            if let error = error {
                // If there's an error, pass false and the error message to the completion handler.
                completion(false, error.localizedDescription)
            } else {
                // If login is successful, update the isLoggedIn state and pass true to the completion handler.
                self.isLoggedIn = self.isUserLoggedIn()
                // Pass a custom success message or use a default message
                let successMessage = "Signed In Successfully!"
                completion(true, successMessage)
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
                        return Book(
                            id: document.documentID,
                            volumeInfo: JSON.null, // Assuming JSON.null is a valid placeholder
                            thumnailUrl: thumnailUrl,
                            title: "Default Title",
                            description: "Default Description"
                        )
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
    
    func uploadModel(_ url: URL, fileType: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "User not authenticated", code: 401, userInfo: nil)))
            return
        }

        let errorFileExtension = "unknown_extension"

        let fileExtension = url.pathExtension.isEmpty ? errorFileExtension : url.pathExtension

        let storageRef = Storage.storage().reference().child("SpatialFiles").child(fileType).child("\(user.uid)/\(UUID().uuidString).\(fileExtension)")

        let uploadTask = storageRef.putFile(from: url, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            storageRef.downloadURL { url, error in
                if let url = url {
                    completion(.success(url))
                } else if let error = error {
                    completion(.failure(error))
                }
            }
        }
    }
}
