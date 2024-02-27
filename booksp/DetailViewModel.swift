//
//  DetailViewModel.swift
//  booksp
//
//  Created by Takuzen Toh on 2/24/24.
//

import Firebase

class DetailViewModel: ObservableObject {
    
    private var db = Firestore.firestore()
    
    func getPostDocument(userID: String, postID: String, completion: @escaping (Post?) -> Void) {
        let postRef = db.collection("users").document(userID).collection("posts").document(postID)
        
        postRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let thumbnailURL = (data?["thumbnailURL"] as? String).flatMap(URL.init)
                let videoURL = data?["videoURL"] as? String ?? ""
                let caption = data?["caption"] as? String
                let fileType = data?["fileType"] as? String ?? ""
                let username = data?["username"] as? String ?? "Unknown"
                let timestamp = data?["timestamp"] as? Timestamp

                let fetchedPost = Post(id: postID, creatorUserID: userID, videoURL: videoURL, thumbnailURL: thumbnailURL, caption: caption, timestamp: timestamp, creationDate: nil, fileType: fileType, username: username)
                
                completion(fetchedPost)
            } else {
                completion(nil)
            }
        }
    }
    
}
