//
//  HomeViewModel.swift
//  booksp
//
//  Created by Takuzen Toh on 2/24/24.
//

import Firebase

class HomeViewModel: ObservableObject {
    
    @Published var homePosts: [Post] = []
    
    private var db = Firestore.firestore()
    
    func fetchHomePosts(completion: @escaping () -> Void) {
        let dispatchGroup = DispatchGroup()

        db.collection("posts").order(by: "timestamp", descending: true).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error fetching posts: \(err.localizedDescription)")
                return
            } else {
                var tempPosts: [Post] = []
                for document in querySnapshot!.documents {
                    dispatchGroup.enter()
                    let data = document.data()
                    let postID = document.documentID
                    let caption = data["caption"] as? String
                    let thumbnailURLString = data["thumbnailURL"] as? String
                    let thumbnailURL = URL(string: thumbnailURLString ?? "")
                    let userID = data["userID"] as? String ?? ""
                    let videoURL = data["videoURL"] as? String ?? ""
                    let fileType = data["fileType"] as? String ?? ""
                    let timestamp = data["timestamp"] as? Timestamp
                    let creationDate = timestamp?.dateValue()

                    self.db.collection("users").document(userID).getDocument { (userDoc, userErr) in
                        if let userErr = userErr {
                            print("Error fetching user: \(userErr.localizedDescription)")
                            dispatchGroup.leave()
                        } else if let userDoc = userDoc, userDoc.exists {
                            let userData = userDoc.data()
                            let username = userData?["username"] as? String ?? "Unknown"
                            let post = Post(id: postID, creatorUserID: userID, videoURL: videoURL, thumbnailURL: thumbnailURL, caption: caption, creationDate: creationDate, fileType: fileType, username: username)
                            tempPosts.append(post)
                            dispatchGroup.leave()
                        } else {
                            print("User document does not exist for userID: \(userID)")
                            dispatchGroup.leave()
                        }
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    self.homePosts = tempPosts
                    completion()
                }
            }
        }
    }
}
