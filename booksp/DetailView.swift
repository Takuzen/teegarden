//
//  DetailView.swift
//  booksp
//
//  Created by Takuzen Toh on 2/24/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct DetailView: View {
    
    init(userID: String, postID: String) {
        self.userID = userID
        self.postID = postID
        _detailViewModel = StateObject(wrappedValue: DetailViewModel())
        _post = State(wrappedValue: nil)
        _username = State(wrappedValue: "")
        _showSpatialPlayer = State(wrappedValue: false)
        _profileImageURL = State(wrappedValue: nil)
    }
    
    @StateObject var detailViewModel = DetailViewModel()
    
    let userID: String
    let postID: String
    
    private var db = Firestore.firestore()
    
    @State private var post: Post?
    @State private var username: String = ""
    @State private var showSpatialPlayer = false
    @State private var profileImageURL: URL?
    @State private var localFileURL: URL?
    @State private var showEtcSheet = false

    private let maxLocalStorageSize: UInt64 = 3 * 1024 * 1024 * 1024
    
    private func fetchProfileImage(for userID: String) {
        FirebaseViewModel.shared.fetchProfileImageURL(for: userID) { url in
            profileImageURL = url
        }
    }
    
    private func getPostDocument(userID: String, postID: String) {
        detailViewModel.getPostDocument(userID: userID, postID: postID) { fetchedPost in
            post = fetchedPost
            if let videoURL = fetchedPost?.videoURL, let fileType = fetchedPost?.fileType {
                downloadVideoFileForQL(from: videoURL, fileType: fileType)
            }
        }
    }
    
    private func fetchUsername(userID: String) {
        let userRef = db.collection("users").document(userID)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                if let username = data?["username"] as? String {
                    self.username = username
                }
            }
        }
    }
    
    private func checkAndCleanStorage(at directoryURL: URL) {
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

    private func downloadVideoFileForQL(from videoURL: String, fileType: String) {
        
        checkAndCleanStorage(at: FileManager.default.temporaryDirectory)

        let storageRef = Storage.storage().reference(forURL: videoURL)
        let fileName = UUID().uuidString + "." + fileType
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        storageRef.write(toFile: localURL) { url, error in
            if let error = error {
                print("Error downloading video file: \(error.localizedDescription)")
            } else if let url = url {
                self.localFileURL = url
            }
        }
    }
    
    private func incrementViewCount() {
        let postRef = db.collection("posts").document(postID)
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let postDocument: DocumentSnapshot
            do {
                try postDocument = transaction.getDocument(postRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }

            guard let oldViewCount = postDocument.data()?["views"] as? Int else {
                let error = NSError(
                    domain: "AppErrorDomain",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unable to retrieve view count from post document."
                    ]
                )
                errorPointer?.pointee = error
                return nil
            }

            transaction.updateData(["views": oldViewCount + 1], forDocument: postRef)
            return nil
        }) { _, error in
            if let error = error {
                print("Transaction failed: \(error)")
            } else {
                print("Transaction successfully committed!")
            }
        }
    }
        
    var body: some View {
        
        VStack {
            
            if let post = post {
                
                NavigationLink(destination: UserView(userID: userID, username: username)) {
                    
                    HStack {
                        
                        if let profileImageURL = profileImageURL {
                            AsyncImage(url: profileImageURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                case .failure(_):
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                case .empty:
                                    ProgressView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                        }
                        
                        Text(username)
                            .bold()
                            .padding(.leading, 5)
                        
                        Spacer()
                        
                        if FirebaseViewModel.shared.isLoggedIn {
                            
                            Button(action: {
                                showEtcSheet = true
                                print("showEtcSheet: \(showEtcSheet)")
                            }) {
                                Image(systemName: "ellipsis")
                                    .frame(width: 30, height: 30)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .actionSheet(isPresented: $showEtcSheet) {
                                ActionSheet(
                                    title: Text("Actions"),
                                    buttons: [
                                        .destructive(Text("Flag")) {
                                            FirebaseViewModel.shared.flagPost(postID: postID)
                                        },
                                        .cancel()
                                    ]
                                )
                            }
                        }
                        
                    }
                    .padding(.bottom, 25)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 800)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        if post.fileType == "mov" {
                            Button(action: {
                                self.showSpatialPlayer = true
                            }) {
                                ZStack {
                                    AsyncImage(url: post.thumbnailURL) { image in
                                        image.resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 800, height: 500)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } placeholder: {
                                        Color.gray
                                            .frame(width: 800, height: 500)
                                    }
                                    Image(systemName: "play.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.white)
                                }
                            }
                            .sheet(isPresented: $showSpatialPlayer) {
                                SpatialVideoPlayer(videoURL: URL(string: post.videoURL)!)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            
                            if let url = localFileURL {
                                USDZQLPreview(url: url)
                                    .frame(width: 800, height: 500)
                            } else {
                                Text("")
                                    .frame(width: 800, height: 500)
                                    .background(Color.gray.opacity(0.5))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            
                        }
                        Text(post.caption ?? "")
                            .frame(width: 800, alignment: .leading)
                            .padding(.top, 20)
                            .padding(.bottom, 20)
                    }
                }
            } else {
                Text("")
            }
        }
        .onAppear {
            fetchProfileImage(for: userID)
            fetchUsername(userID: userID)
            getPostDocument(userID: userID, postID: postID)
            incrementViewCount()
        }
    }
}
