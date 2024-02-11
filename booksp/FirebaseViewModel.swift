//
//  Firebase.swift
//  booksp
//
//  Created by Taku on 2023/07/29.
//

import UIKit

extension UIImage {
    func imageData() -> Data? {
        return self.pngData() ?? self.jpegData(compressionQuality: 0.9)
    }
}

import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftyJSON
import Foundation

class FirebaseViewModel: ObservableObject {
    @Published var userProfileImageURL: URL?
    
    static let shared: FirebaseViewModel = .init()
    
    private let maxLocalStorageSize: UInt64 = 10 * 1024 * 1024 * 1024
    
    @Published var isLoggedIn:Bool = false
    @Published var username: String = ""
    @Published var mail: String = ""
    @Published var password: String = ""
    @Published var userFirstName: String = ""
    @Published var userLastName: String = ""
    @Published var errorMessage: String = ""
    @Published var favoriteBooks: [Book] = []
    @Published var fileURLs: [URL] = []
    
    @Published var postsWithMetadata: [PostWithMetadata] = []
    
    struct PostWithMetadata {
        var id: String
        var caption: String
        var thumbnailURL: String
        var username: String
        var videoURL: String?
    }

    func fetchPostsWithMetadata() {
        db.collection("posts").getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                var tempPosts: [PostWithMetadata] = []
                for document in querySnapshot!.documents {
                    let data = document.data()
                    let postID = document.documentID
                    let caption = data["caption"] as? String ?? ""
                    let thumbnailURL = data["thumbnailURL"] as? String ?? ""
                    let videoURL = data["videoURL"] as? String
                    let userID = data["userID"] as? String ?? ""
                    
                    // Now fetch the username using userID
                    self.db.collection("users").document(userID).getDocument { (userDoc, userErr) in
                        if let userErr = userErr {
                            print("Error fetching user: \(userErr)")
                        } else if let userDoc = userDoc, userDoc.exists {
                            let userData = userDoc.data()
                            let username = userData?["username"] as? String ?? "Unknown"
                            
                            // Include the videoURL when creating a PostWithMetadata object
                            let postWithMeta = PostWithMetadata(id: postID, caption: caption, thumbnailURL: thumbnailURL, username: username, videoURL: videoURL)
                            tempPosts.append(postWithMeta)
                            
                            // Update the published variable
                            DispatchQueue.main.async {
                                self.postsWithMetadata = tempPosts
                            }
                        } else {
                            print("User document does not exist")
                        }
                    }
                }
            }
        }
    }

    private var storageRef = Storage.storage().reference()
    private var db = Firestore.firestore()
    
    func createPost(forUserID userID: String, videoURL: String, thumbnailURL: String, caption: String) {
            // Create a reference for a new post ID in the user's sub-collection.
            let userPostRef = db.collection("users").document(userID).collection("posts").document()
            let globalPostRef = db.collection("posts").document(userPostRef.documentID)
            
            let postData = [
                "videoURL": videoURL,
                "thumbnailURL": thumbnailURL,
                "caption": caption,
                "timestamp": Timestamp(date: Date())
            ] as [String : Any]
            
            print("Attempting to write to userId: \(userID)")
            print("Authenticated user's uid: \(Auth.auth().currentUser?.uid ?? "No Auth user found")")
            
            userPostRef.setData(postData) { error in
                if let error = error {
                    print("Error adding post to user's collection: \(error.localizedDescription)")
                } else {
                    print("Post added to user's collection successfully")
                    
                    let globalPostData = postData.merging(["userID": userID]) { (current, _) in current }
                    
                    globalPostRef.setData(globalPostData) { error in
                        if let error = error {
                            print("Error adding post to global posts collection: \(error.localizedDescription)")
                        } else {
                            print("Post added to global posts collection successfully")
                        }
                    }
                }
            }
        }
    
    func uploadVideoAndThumbnail(videoURL: URL, thumbnailURL: URL, completion: @escaping (URL?, URL?) -> Void) {
        let uniqueID = UUID().uuidString
        let videoStorageRef = storageRef.child("SpatialFiles/mov/\(uniqueID)/\(uniqueID).mov")
        let thumbnailStorageRef = storageRef.child("SpatialFiles/mov/\(uniqueID)/\(uniqueID)_thumbnail.jpg")
        print("[PONG] About to upload the video")
        
        if FileManager.default.fileExists(atPath: videoURL.path) {
            print("File exists and is ready for upload.")
        } else {
            print("File does not exist at path: \(videoURL.path)")
        }
        
        print("Is user authenticated: \(Auth.auth().currentUser != nil)")
        
        let uploadTaskVideo = videoStorageRef.putFile(from: videoURL, metadata: nil) { metadata, error in
            if let error = error {
                print("Failed to upload video: \(error.localizedDescription)")
            }
            
            guard metadata != nil else {
                print("Upload failed, metadata is nil.")
                print("metadata = \(String(describing: metadata))")
                completion(nil, nil)
                return
            }
            
            print("[PONG] Video uploaded successfully, URL: \(videoURL)")
            
            print("[PONG] About to fetch videodownload URL.")
            
            // Fetch the download URL for the video
            videoStorageRef.downloadURL { videoDownloadURL, error in
                guard let videoDownloadURL = videoDownloadURL else {
                    print("Video URL not found: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil, nil)
                    return
                }
                
                print("[PONG] video got Downloaded successfully, URL: \(videoDownloadURL)")
                
                print("[PONG] About to upload thumbnail")
                // Upload the thumbnail
                let uploadTaskThumbnail = thumbnailStorageRef.putFile(from: thumbnailURL, metadata: nil) { metadata, error in
                    guard metadata != nil else {
                        print("Failed to upload thumbnail: \(error?.localizedDescription ?? "Unknown error")")
                        completion(videoDownloadURL, nil)
                        return
                    }
                    
                    print("[PONG] Thumbnail uploaded successfully, URL: \(thumbnailURL)")
                    
                    print("[PONG] About to download thumbnailDownloadURL")
                    // Fetch the download URL for the thumbnail
                    thumbnailStorageRef.downloadURL { thumbnailDownloadURL, error in
                        guard let thumbnailDownloadURL = thumbnailDownloadURL else {
                            print("Thumbnail URL not found: \(error?.localizedDescription ?? "Unknown error")")
                            completion(videoDownloadURL, nil)
                            return
                        }
                        
                        print("[PONG] Thumbnail got downloaded successfully, URL: \(thumbnailDownloadURL)")
                        
                        print("[PONG] Both uploads are successful, return the URLs")
                        completion(videoDownloadURL, thumbnailDownloadURL)
                    }
                }
            }
        }
    }
    
    func fetchUserProfile() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let profileImageURLString = data?["profileImageURL"] as? String,
                   let profileImageURL = URL(string: profileImageURLString) {
                    DispatchQueue.main.async {
                        self.userProfileImageURL = profileImageURL
                    }
                }
                // Fetch other user data as needed
            } else {
                print("User does not exist")
            }
        }
    }
    
    func updateUserProfileImageURL(userID: String, imageURL: URL, completion: @escaping (Error?) -> Void) {
        let databaseRef = Firestore.firestore().collection("users").document(userID)
        
        databaseRef.updateData(["profileImageURL": imageURL.absoluteString]) { error in
            completion(error)
        }
    }
    
    func downloadVideoFileForQL(from videoURL: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = Storage.storage().reference(forURL: videoURL)
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
        
        // Download to the local file URL
        storageRef.write(toFile: localURL) { url, error in
            if let error = error {
                completion(.failure(error))
            } else if let url = url {
                completion(.success(url))
            }
        }
    }


    func signUp(firstName: String, lastName: String, username: String, completion: @escaping (Bool, String) -> Void) {
        // Create a new user account with email and password
        Auth.auth().createUser(withEmail: mail, password: password) { authResult, error in
            if let error = error {
                // If there's an error in account creation, return the error
                completion(false, error.localizedDescription)
                return
            }
            
            guard let authResult = authResult else {
                // If the result is nil, an unknown error occurred
                completion(false, "An unknown error occurred.")
                return
            }
            
            // Get the user ID of the newly created user
            let userId = authResult.user.uid
            
            // Prepare the additional user data to write to Firestore
            let userData: [String: Any] = [
                "firstName": firstName,
                "lastName": lastName,
                "email": self.mail,
                "username": username
            ]
            
            // Store the additional user data in Firestore
            self.storeUserData(userId: userId, data: userData) { success, message in
                if success {
                    // If writing to Firestore succeeded, update the local user properties
                    DispatchQueue.main.async {
                        self.userFirstName = firstName
                        self.userLastName = lastName
                        self.username = username
                    }
                }
                // Return the result of writing to Firestore
                completion(success, message)
            }
        }
    }

    func uploadProfileImage(userID: String, image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        let imageData: Data?
        let fileExtension: String
        
        if let jpegData = image.jpegData(compressionQuality: 0.75) {
            imageData = jpegData
            fileExtension = "jpg"
        } else if let pngData = image.pngData() {
            imageData = pngData
            fileExtension = "png"
        } else {
            // Fallback or additional check for other formats like HEIC
            // iOS does not directly provide a function to get HEIC data from UIImage
            // You may need to handle HEIC differently or convert to JPEG/PNG
            completion(.failure(NSError(domain: "ImageUploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unsupported image format."])))
            return
        }
        
        guard let uploadData = imageData else {
            completion(.failure(NSError(domain: "ImageUploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get image data."])))
            return
        }
        
        let storageRef = Storage.storage().reference().child("personal/\(userID)/profileImage/profileImage.\(fileExtension)")
        
        storageRef.putData(uploadData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "ImageUploadError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not get download URL."])))
                    return
                }
                completion(.success(downloadURL))
            }
        }
    }

    func storeUserData(userId: String, data: [String: Any], completion: @escaping (Bool, String) -> Void) {
        // Reference to the Firestore database
        let db = Firestore.firestore()
        
        // Set the data for the specific user
        db.collection("users").document(userId).setData(data) { error in
            if let error = error {
                completion(false, "Error writing user data: \(error.localizedDescription)")
            } else {
                completion(true, "User data successfully written!")
            }
        }
    }

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
    
    func isUserLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = self.isUserLoggedIn()
        } catch let signOutError as NSError {
            self.errorMessage = "Error signing out: \(signOutError.localizedDescription)"
        }
    }

}
