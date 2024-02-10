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

struct SpatialVideoMetadata {
    let thumbnailURL: String
    let videoURL: String?
    let size: Int64
    let timeCreated: Date
    var localURL: URL?
    var username: String?
    var caption: String?
}

class FirebaseViewModel: ObservableObject {
    @Published var userProfileImageURL: URL?
    
    static let shared: FirebaseViewModel = .init()
    
    private var fileDownloader = FileDownloader()
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
    @Published var metadata: SpatialVideoMetadata?
    @Published var spatialVideoMetadataArray: [SpatialVideoMetadata] = []
    
    @Published var postsWithMetadata: [PostWithMetadata] = []
    
    struct PostWithMetadata {
        var id: String
        var caption: String
        var thumbnailURL: String
        var username: String
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
                    let userID = data["userID"] as? String ?? ""
                    
                    // Now fetch the username using userID
                    self.db.collection("users").document(userID).getDocument { (userDoc, userErr) in
                        if let userErr = userErr {
                            print("Error fetching user: \(userErr)")
                        } else if let userDoc = userDoc, userDoc.exists {
                            let userData = userDoc.data()
                            let username = userData?["username"] as? String ?? "Unknown"
                            
                            // Create a PostWithMetadata object and append it to tempPosts
                            let postWithMeta = PostWithMetadata(id: postID, caption: caption, thumbnailURL: thumbnailURL, username: username)
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
                if let profileImageURLString = data?["profileImageUrl"] as? String,
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

    func updateMetadata(localURL: URL, for videoURL: String) {
        if let index = self.spatialVideoMetadataArray.firstIndex(where: { $0.videoURL == videoURL }) {
            self.spatialVideoMetadataArray[index].localURL = localURL
        }
    }
    
    func handleFileDownload(metadata: SpatialVideoMetadata) {
        guard let remoteURL = metadata.videoURL, let url = URL(string: remoteURL) else {
            print("Invalid URL")
            return
        }
        
        fileDownloader.downloadFile(from: url, maxSize: maxLocalStorageSize) { localURL, error in
            DispatchQueue.main.async {
                if let localURL = localURL {
                    print("localURL: \(localURL)")
                    
                    // Update the metadata in your ViewModel
                    self.updateMetadata(localURL: localURL, for: remoteURL)
                    
                } else if let error = error {
                    // Handle the error, e.g., log it or show an error message to the user
                    print("Error downloading file: \(error.localizedDescription)")
                }
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

    func uploadProfileImage(userId: String, imageData: Data, completion: @escaping (_ url: String?) -> Void) {
            // Create a reference to the Firebase Storage location
        let storageRef = Storage.storage().reference().child("profileImages/\(userId).jpg")

        // Begin the image upload task
        storageRef.putData(imageData, metadata: nil) { (metadata, error) in
            if let error = error {
                // If there's an error during upload, print the error and call the completion with nil
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
            } else {
                // If the upload was successful, retrieve the download URL
                storageRef.downloadURL { (url, error) in
                    if let error = error {
                        // If there's an error retrieving the download URL, print the error and call the completion with nil
                        print("Error getting download URL: \(error.localizedDescription)")
                        completion(nil)
                    } else if let downloadURL = url {
                        // If successful, call the completion handler with the download URL string
                        completion(downloadURL.absoluteString)
                    }
                }
            }
        }
    }

    func updateProfileImageUrl(userId: String, imageURL: String, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)

        userRef.updateData(["profileImageUrl": imageURL]) { error in
            if let error = error {
                print("Error updating user's profile image URL: \(error.localizedDescription)")
            } else {
                print("User's profile image URL updated successfully with \(imageURL)")
            }
            completion()
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
    
    enum UploadError: Error {
        case authenticationFailed
        case invalidModelURL
        case invalidThumbnailURL
        case uploadFailed(Error)
        case urlGenerationFailed
    }
    
    func uploadCube(modelURL: URL, thumbnailURL: URL?, fileType: String, completion: @escaping (Result<(modelURL: URL, thumbnailURL: URL?), UploadError>) -> Void) {
        
        guard let user = Auth.auth().currentUser else {
            completion(.failure(.authenticationFailed))
            return
        }

        let errorFileExtension = "unknown_extension"
        let fileExtension = modelURL.pathExtension.isEmpty ? errorFileExtension : modelURL.pathExtension
        let uniqueFolderName = UUID().uuidString
        let modelStoragePath = "SpatialFiles/\(fileType)/\(uniqueFolderName)/\(uniqueFolderName).\(fileExtension)"
        let modelStorageRef = Storage.storage().reference().child(modelStoragePath)
        
        modelStorageRef.putFile(from: modelURL, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(.uploadFailed(error)))
                return
            }
            modelStorageRef.downloadURL { modelDownloadURL, error in
                if let error = error {
                    completion(.failure(.uploadFailed(error)))
                    return
                }
                
                guard let modelDownloadURL = modelDownloadURL else {
                    completion(.failure(.invalidModelURL))
                    return
                }
                
                // If there's no thumbnail, complete the operation here
                guard let thumbnailURL = thumbnailURL else {
                    completion(.success((modelDownloadURL, nil)))
                    return
                }
                
                let thumbnailExtension = thumbnailURL.pathExtension.isEmpty ? errorFileExtension : thumbnailURL.pathExtension
                let thumbnailStoragePath = "SpatialFiles/\(fileType)/\(uniqueFolderName)/\(uniqueFolderName)_thumbnail.\(thumbnailExtension)"
                let thumbnailStorageRef = Storage.storage().reference().child(thumbnailStoragePath)
                
                thumbnailStorageRef.putFile(from: thumbnailURL, metadata: nil) { metadata, error in
                    if let error = error {
                        completion(.failure(.uploadFailed(error)))
                        return
                    }
                    thumbnailStorageRef.downloadURL { thumbnailDownloadURL, error in
                        if let error = error {
                            completion(.failure(.uploadFailed(error)))
                            return
                        }
                        
                        guard let thumbnailDownloadURL = thumbnailDownloadURL else {
                            completion(.failure(.invalidThumbnailURL))
                            return
                        }
                        
                        // Return both URLs
                        completion(.success((modelDownloadURL, thumbnailDownloadURL)))
                    }
                }
            }
        }
    }
    
    class FileDownloader {
        // Function to get the size of a directory
        private func getSizeOfDirectory(at directoryURL: URL) throws -> UInt64 {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.fileSizeKey], options: .skipsHiddenFiles)
            var size: UInt64 = 0
            
            for url in contents {
                let fileSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                size += UInt64(fileSize)
            }
            return size
            }

            // Function to delete the oldest files when storage limit is exceeded
            private func deleteOldestFiles(in directoryURL: URL, maxSize: UInt64) throws {
                let fileManager = FileManager.default
                let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
                
                let sortedFiles = contents.sorted {
                    let date0 = try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate
                    let date1 = try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate
                    return date0 ?? Date.distantPast < date1 ?? Date.distantPast
                }
                
                var totalSize = try getSizeOfDirectory(at: directoryURL)
                for fileURL in sortedFiles {
                    guard totalSize > maxSize else { break }
                    let fileSize = try fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    try fileManager.removeItem(at: fileURL)
                    totalSize -= UInt64(fileSize)
                }
            }

        // Function to download file from URL and save it locally
        func downloadFile(from url: URL, maxSize: UInt64, completion: @escaping (URL?, Error?) -> Void) {
                let sessionConfig = URLSessionConfiguration.default
                let session = URLSession(configuration: sessionConfig)
                let fileManager = FileManager.default
                
                let downloadTask = session.downloadTask(with: url) { tempLocalUrl, response, error in
                    if let tempLocalUrl = tempLocalUrl, error == nil {
                        // Attempt to manage local storage before saving the new file
                        do {
                            // Get the directory URL for saving the file
                            let directoryURL = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                            
                            // Construct the final local URL for the downloaded file
                            let savedURL = directoryURL.appendingPathComponent(url.lastPathComponent)
                            
                            // Check if a file with the same name already exists at the destination
                            if fileManager.fileExists(atPath: savedURL.path) {
                                // Remove the existing file to avoid the naming conflict
                                try fileManager.removeItem(at: savedURL)
                            }
                            
                            // Move the file from the temporary URL to the desired location
                            try fileManager.moveItem(at: tempLocalUrl, to: savedURL)
                            
                            // Call completion with the URL where the file was saved
                            completion(savedURL, nil)
                        } catch {
                            print("File download or move error: \(error.localizedDescription)")
                            completion(nil, error)
                        }
                    } else {
                        print("Error took place: \(error?.localizedDescription ?? "Unknown error")")
                        completion(nil, error)
                    }
                }
                downloadTask.resume()
            }

    }

}
