//
//  UserViewModel.swift
//  booksp
//
//  Created by Takuzen Toh on 2/22/24.
//

import Foundation
import Firebase

class UserPostsViewModel: ObservableObject {
    
    @Published var userPosts: [Post] = []

    func fetchUserPosts(userID: String) {

        let postsRef = Firestore.firestore().collection("users").document(userID).collection("posts")
            .order(by: "timestamp", descending: true)

        postsRef.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error getting posts: \(error.localizedDescription)")
                return
            }

            var tempPosts: [Post] = []
            for document in querySnapshot!.documents {
                let data = document.data()
                let thumbnailURL = (data["thumbnailURL"] as? String).flatMap(URL.init)
                let videoURL = (data["videoURL"] as? String).flatMap(URL.init)
                let caption = data["caption"] as? String
                let fileType = data["fileType"] as? String
                
                if let fileType = fileType, let videoURLString = videoURL?.absoluteString {
                    let username = data["username"] as? String ?? "Unknown"
                    let post = Post(id: document.documentID, creatorUserID: userID, videoURL: videoURLString, thumbnailURL: thumbnailURL, caption: caption, fileType: fileType, username: username)
                    tempPosts.append(post)
                }
            }

            DispatchQueue.main.async {
                self.userPosts = tempPosts
            }
        }
    }
}
