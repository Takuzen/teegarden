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
    @Published var fileURLs: [URL] = []

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
    
    @Published var thumbnailsMetadata: [SpatialVideoMetadata] = []
    
    func fetchThumbnailsMetadata(completion: @escaping (Result<[SpatialVideoMetadata], Error>) -> Void) {
        let baseRef = Storage.storage().reference().child("SpatialFiles/mov/")
        baseRef.listAll { (baseResult, baseError) in
            if let baseError = baseError {
                completion(.failure(baseError))
                return
            }
            
            // Safely unwrap baseResult
            guard let baseResult = baseResult else {
                completion(.failure(NSError(domain: "FirebaseViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to list directories in base path."])))
                return
            }
            
            var spatialVideoMetadataList: [SpatialVideoMetadata] = []
            let group = DispatchGroup()
            
            for folderRef in baseResult.prefixes {
                group.enter()
                folderRef.listAll { (folderResult, folderError) in
                    if let folderError = folderError {
                        print("Error listing folder: \(folderError)")
                        group.leave()
                        return
                    }
                    
                    // Safely unwrap folderResult
                    guard let folderResult = folderResult else {
                        print("Folder result is nil")
                        group.leave()
                        return
                    }
                    
                    for item in folderResult.items {
                        group.enter()
                        item.getMetadata { metadata, error in
                            if let error = error {
                                print("Error getting metadata for item \(item): \(error)")
                                group.leave()
                                return
                            }
                            if let metadata = metadata,
                               let name = metadata.name, // Safely unwrap name here
                               let timeCreated = metadata.timeCreated,
                               name.hasSuffix("_thumbnail.jpg") { // Now you can call hasSuffix
                                item.downloadURL { (thumbnailURL, error) in
                                    if let error = error {
                                        print("Error getting download URL for item \(item): \(error)")
                                        group.leave()
                                        return
                                    }
                                    if let thumbnailDownloadURL = thumbnailURL {
                                        // Construct the path for the corresponding .mov file
                                        let videoName = name.replacingOccurrences(of: "_thumbnail.jpg", with: ".mov")
                                        let videoPath = "SpatialFiles/mov/\(folderRef.name)/\(videoName)"
                                        let videoStorageRef = Storage.storage().reference().child(videoPath)
                                        
                                        // Fetch the download URL for the .mov file
                                        videoStorageRef.downloadURL { (videoURL, error) in
                                            if let error = error {
                                                print("Error getting download URL for video \(videoName): \(error)")
                                                group.leave()
                                                return
                                            }
                                            
                                            let videoMetadata = SpatialVideoMetadata(
                                                videoURL: videoURL?.absoluteString,
                                                thumbnailURL: thumbnailDownloadURL.absoluteString,
                                                size: metadata.size,
                                                timeCreated: timeCreated
                                            )
                                            spatialVideoMetadataList.append(videoMetadata)
                                            group.leave()
                                        }
                                    } else {
                                        group.leave()
                                    }
                                }
                            } else {
                                group.leave()
                            }
                        }
                    }
                    
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                // Sort by time created, newest first
                spatialVideoMetadataList.sort { $0.timeCreated > $1.timeCreated }
                self.thumbnailsMetadata = spatialVideoMetadataList
                completion(.success(spatialVideoMetadataList))
            }
        }
    }

    
}
