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
    
    
    func loadData() {
        fetchAndSortFiles { [weak self] sortedFiles in
            guard let self = self else { return }
            print("Fetched and sorted files: \(sortedFiles)")
            
            for fileRef in sortedFiles {
                self.downloadAndCacheFile(fileRef: fileRef) { localURL in
                    DispatchQueue.main.async {
                        if let localURL = localURL {
                            print("Downloaded and cached file: \(localURL)")
                            self.fileURLs.append(localURL)
                            self.manageLocalStorage()
                        } else {
                            print("Failed to download or cache file for reference: \(fileRef)")
                        }
                    }
                }
            }
        }
    }

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
        let modelStoragePath = "SpatialFiles/\(fileType)/\(uniqueFolderName).\(fileExtension)"
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

    
    func fetchFiles(completion: @escaping ([StorageReference]) -> Void) {
        let storageRef = Storage.storage().reference().child("SpatialFiles/mov")
        
        // Print the path for debugging
        print("Attempting to list files at path: \(storageRef.fullPath)")
        
        storageRef.listAll { (result, error) in

            if let error = error {
                // If there was an error, print it and return an empty array
                print("Error listing files: \(error.localizedDescription)")
                completion([])
                return
            }
            
            if let result = result {
                // If the result is not nil, we have our list of files
                let files = result.items // You get the list of files
                completion(files)
            } else {
                // If the result is nil, there are no files, return an empty array
                print("No files found")
                completion([])
            }
        }
    }
    
    func fetchAndSortFiles(completion: @escaping ([StorageReference]) -> Void) {
        fetchFiles { files in
            let group = DispatchGroup()
            var filesWithDates: [(ref: StorageReference, date: Date?)] = []
            
            for file in files {
                group.enter()
                file.getMetadata { metadata, error in
                    if let creationDate = metadata?.timeCreated {
                        filesWithDates.append((ref: file, date: creationDate))
                    } else {
                        filesWithDates.append((ref: file, date: nil))
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                let sortedFiles = filesWithDates
                    .filter { $0.date != nil }
                    .sorted { $0.date! > $1.date! }
                    .map { $0.ref }
                
                completion(sortedFiles)
            }
        }
    }

    func downloadAndCacheFile(fileRef: StorageReference, completion: @escaping (URL?) -> Void) {
        // Define the local file URL (consider using the cache directory)
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileRef.name)
        
        // Check if file already exists
        if FileManager.default.fileExists(atPath: localURL.path) {
            completion(localURL) // File already cached
            return
        }
        
        // Download to the local file URL
        fileRef.write(toFile: localURL) { url, error in
            if let error = error {
                print(error)
                completion(nil)
            } else {
                completion(localURL)
            }
        }
    }
    
    func manageLocalStorage(maxStorageLimit: Int64 = 1024 * 1024 * 500) { // 500MB limit by default
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.temporaryDirectory
        var totalSize: Int64 = 0
        
        do {
            // Get the directory contents
            let directoryContents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey], options: .skipsHiddenFiles)
            
            // Map files with their properties
            let filesAndProperties = try directoryContents.map { file -> (URL, Date?, Int64) in
                let resourceValues = try file.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey])
                let fileSize = Int64(resourceValues.fileSize ?? 0)
                return (file, resourceValues.contentModificationDate, fileSize)
            }

            
            // Sort files by date, oldest first
            let sortedFiles = filesAndProperties.sorted {
                guard let first = $0.1, let second = $1.1 else { return false }
                return first < second
            }
            
            // Remove files if the total size exceeds the limit
            for file in sortedFiles {
                totalSize += file.2
                if totalSize > maxStorageLimit {
                    try fileManager.removeItem(at: file.0)
                    totalSize -= file.2
                }
            }
        } catch {
            print("There was an error managing the local storage: \(error)")
        }
    }

    
}
