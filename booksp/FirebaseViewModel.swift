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
    
    static let shared: FirebaseViewModel = .init()
    private init() {} // Private initializer to ensure singleton usage
    
    @Published var introductionText: String = ""
    
    @Published var isLoggedIn: Bool = false
    @Published var userID: String = ""
    @Published var username: String = ""
    @Published var mail: String = ""
    @Published var password: String = ""
    @Published var userFirstName: String = ""
    @Published var userLastName: String = ""
    @Published var errorMessage: String = ""
    @Published var favoriteBooks: [Book] = []
    @Published var fileURLs: [URL] = []

    @Published var blockSuccessMessage: String = ""
    @Published var blockFailureMessage: String = ""
    
    private var storageRef = Storage.storage().reference()
    private var db = Firestore.firestore()
    
    private let maxLocalStorageSize: UInt64 = 3 * 1024 * 1024 * 1024
    
    func fetchIntroductionText(userID: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let introduction = data?["introduction"] as? String {
                    DispatchQueue.main.async {
                        self.introductionText = introduction
                    }
                }
            } else {
                
            }
        }
    }
        
    func updateIntroductionText(userID: String, introduction: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userID).updateData(["introduction": introduction]) { error in
            if let error = error {
                
            } else {
                
            }
        }
    }
    
    func createPost(forUserID userID: String, videoURL: String, thumbnailURL: String, caption: String, fileType: String) {
 
            let userPostRef = db.collection("users").document(userID).collection("posts").document()
            let globalPostRef = db.collection("posts").document(userPostRef.documentID)
            
            let postData = [
                "videoURL": videoURL,
                "thumbnailURL": thumbnailURL,
                "caption": caption,
                "timestamp": Timestamp(date: Date()),
                "fileType": fileType
            ] as [String : Any]
            
            userPostRef.setData(postData) { error in
                if let error = error {
                    
                } else {
                    
                    
                    let globalPostData = postData.merging(["userID": userID]) { (current, _) in current }
                    
                    globalPostRef.setData(globalPostData) { error in
                        if let error = error {
                            
                        } else {
                            
                        }
                    }
                }
            }
        }
    
    func uploadFileAndThumbnail(fileURL: URL, thumbnailURL: URL?, fileType: String, completion: @escaping (URL?, URL?) -> Void) {
        let uniqueID = UUID().uuidString
        let fileStorageRef = storageRef.child("SpatialFiles/\(fileType)/\(uniqueID)/\(uniqueID).\(fileType)")
        var thumbnailStorageRef: StorageReference?
        if let thumbnailURL = thumbnailURL {
            thumbnailStorageRef = storageRef.child("SpatialFiles/\(fileType)/\(uniqueID)/\(uniqueID)_thumbnail.jpg")
        }
        
        
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            
        } else {
            
        }
        
        let uploadTaskFile = fileStorageRef.putFile(from: fileURL, metadata: nil) { metadata, error in
            if let error = error {
                print("Error getting posts: \(error.localizedDescription)")
                completion(nil, nil)
                return
            }
            
            guard metadata != nil else {
                
                completion(nil, nil)
                return
            }
            
            fileStorageRef.downloadURL { fileDownloadURL, error in
                if let thumbnailURL = thumbnailURL, let thumbnailStorageRef = thumbnailStorageRef {
                    let uploadTaskThumbnail = thumbnailStorageRef.putFile(from: thumbnailURL, metadata: nil) { metadata, error in
                        guard metadata != nil else {
                            
                            completion(fileDownloadURL, nil)
                            return
                        }
                        
                        thumbnailStorageRef.downloadURL { thumbnailDownloadURL, error in
                            guard let thumbnailDownloadURL = thumbnailDownloadURL else {
                                
                                completion(fileDownloadURL, nil)
                                return
                            }
                            
                            completion(fileDownloadURL, thumbnailDownloadURL)
                        }
                    }
                } else {
                    // No thumbnail to upload
                    completion(fileDownloadURL, nil)
                }
            }
        }
    }

    func fetchProfileImageURL(for userID: String, completion: @escaping (URL?) -> Void) {
        let db = Firestore.firestore()

        db.collection("users").document(userID).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let profileImageURLString = data?["profileImageURL"] as? String,
                   let profileImageURL = URL(string: profileImageURLString) {
                    DispatchQueue.main.async {
                        completion(profileImageURL)
                    }
                } else {
                    completion(nil)
                }
            } else {
                
                completion(nil)
            }
        }
    }

    func fetchUserProfile(userID: String) {
        let db = Firestore.firestore()

        db.collection("users").document(userID).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let email = data?["email"] as? String,
                   let username = data?["username"] as? String {
                    DispatchQueue.main.async {
                        self.mail = email
                        self.username = username
                        self.userID = userID
                    }
                }
            } else {
                
            }
        }
    }

    
    func updateUserProfileImageURL(userID: String, imageURL: URL, completion: @escaping (Error?) -> Void) {
        let databaseRef = Firestore.firestore().collection("users").document(userID)
        
        databaseRef.updateData(["profileImageURL": imageURL.absoluteString]) { error in
            completion(error)
        }
    }

    func checkAndCleanStorage(at directoryURL: URL) {
        let fileManager = FileManager.default

        do {
            let contents = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
            var totalSize = try contents.reduce(UInt64(0)) { total, fileURL in
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                let fileSize = attributes[.size] as? UInt64 ?? 0
                return total + fileSize
            }

            if totalSize > maxLocalStorageSize {
                let sortedFiles = contents.sorted { lhs, rhs in
                    let lhsDate: Date
                    let rhsDate: Date
                    do {
                        lhsDate = try lhs.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                        rhsDate = try rhs.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    } catch {
                        
                        return false
                    }
                    return lhsDate < rhsDate
                }


                for fileURL in sortedFiles {
                    try fileManager.removeItem(at: fileURL)
                    totalSize -= (try fileManager.attributesOfItem(atPath: fileURL.path)[.size] as? UInt64 ?? 0)

                    if totalSize <= maxLocalStorageSize {
                        break
                    }
                }
            }
        } catch {}
    }
    
    func downloadVideoFileForQL(from videoURL: String, fileType: String, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let url = URL(string: videoURL) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        // Check and clean storage before starting the download
        checkAndCleanStorage(at: FileManager.default.temporaryDirectory)

        let storageRef = Storage.storage().reference(forURL: videoURL)
        let fileName = UUID().uuidString + "." + fileType
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        // Download to the local file URL
        storageRef.write(toFile: localURL) { url, error in
            if let error = error {
                completion(.failure(error))
            } else if let url = url {
                completion(.success(url))
            }
        }
    }

    func signUp(username: String, completion: @escaping (Bool, String) -> Void) {
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
                "email": self.mail,
                "username": username
            ]
            
            // Store the additional user data in Firestore
            self.storeUserData(userId: userId, data: userData) { success, message in
                if success {
                    // If writing to Firestore succeeded, update the local user properties
                    DispatchQueue.main.async {
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

        let db = Firestore.firestore()
        
        db.collection("users").document(userId).setData(data) { error in
            if let error = error {
                completion(false, "Error writing user data: \(error.localizedDescription)")
            } else {
                completion(true, "User data successfully written!")
            }
        }
    }

    func login(email: String, password: String, completion: @escaping (Bool, String) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
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
            DispatchQueue.main.async {
                self.isLoggedIn = false
            }
        } catch let signOutError as NSError {
            DispatchQueue.main.async {
                self.errorMessage = "Error signing out: \(signOutError.localizedDescription)"
            }
        }
    }
    
    func blockCustomer(targetCustomerID: String /*, reason: String*/ ) {
        // Ensure the user is logged in before allowing them to flag content
        guard isLoggedIn, !userID.isEmpty else {
            errorMessage = "User must be logged in to flag content."
            return
        }

        // Create a reference to the flagged_content collection
        let blockedCustomerRef = db.collection("blocked_customer").document()

        // Set up the data for the flagged content
        let targetCustomerData = [
            "targetCustomerID": targetCustomerID,
            "blockedBy": Auth.auth().currentUser?.uid ?? "Not available",
            /* "flagReason": reason, */
            "timestamp": Timestamp(date: Date()),
            "status": "pending"
        ] as [String : Any]

        // Add the flagged content data to the Firestore collection
        blockedCustomerRef.setData(targetCustomerData) { error in
            if let error = error {
                self.blockFailureMessage = "Error block customer: \(error.localizedDescription)"
            } else {
                // Successfully flagged content
                DispatchQueue.main.async {
                    self.blockSuccessMessage = "The customer has been successfully blocked. We will address the issue promptly."
                }
            }
        }
    }
    
    func fetchUsername(userID: String, completion: @escaping (String) -> Void) {
            let userRef = db.collection("users").document(userID)
            
            userRef.getDocument { document, error in
                if let document = document, document.exists, let userData = document.data() {
                    if let fetchedUsername = userData["username"] as? String {
                        DispatchQueue.main.async {
                            self.username = fetchedUsername
                            completion(fetchedUsername)
                        }
                    } else {
                        print("Username not found.")
                        completion("")
                    }
                } else if let error = error {
                    print("Error fetching username: \(error.localizedDescription)")
                    completion("")
                }
            }
        }
    
}
