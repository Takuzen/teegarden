//
//  UserView.swift
//  booksp
//
//  Created by Takuzen Toh on 2/22/24.
//

import Foundation
import SwiftUI
import Firebase
import RealityKit

struct UserView: View {

    var userID: String
    var username: String
    
    @StateObject private var userPostsViewModel = UserPostsViewModel()
    
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var isEditingIntroduction: Bool = false
    @State private var newIntroductionText = ""
    @State private var profileImageURL: URL?
    @State private var emailCopied = false
    @State private var showDeletionSheet = false
    @State private var confirmDeletionAlert = false
    @State private var showEtcSheet = false
    // @State private var confirmBlockAlert = false
    
    @State private var localBlockSuccessSheet = false
    @State private var localBlockFailureSheet = false

    var body: some View {
        
        NavigationStack {
            
            ScrollView(.vertical, showsIndicators: true) {
                
                VStack {
                    
                    Spacer()
                    
                    HStack {
                        
                        VStack {
                            
                            if let profileImageURL = profileImageURL {
                                
                                AsyncImage(url: profileImageURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image.resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                            .padding()
                                    case .failure(_):
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                            .padding()
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
                            
                            if userID == Auth.auth().currentUser?.uid {
                                
                                Button("Upload Profile Image") {
                                    showingImagePicker = true
                                }
                                .padding(.top, 5)
                                
                            }
                            
                            Text(username)
                                .bold()
                                .padding()
                            
                            if userID == Auth.auth().currentUser?.uid {
                                
                                Button(action: {
                                    showDeletionSheet = true
                                }) {
                                    Image(systemName: "ellipsis")
                                        .frame(width: 30, height: 30)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .actionSheet(isPresented: $showDeletionSheet) {
                                    ActionSheet(
                                        title: Text("Actions"),
                                        buttons: [
                                            .destructive(Text("Delete My Account")) {
                                                sendDeletionRequest()
                                                confirmDeletionAlert = true
                                            },
                                            .cancel()
                                        ]
                                    )
                                }
                                .alert(isPresented: $confirmDeletionAlert) {
                                    Alert(
                                        title: Text("Account Deletion Requested"),
                                        message: Text("We will completely delete your account and all related information in 14 days. Please contact support@teegarden.app if you wish to cancel the deletion request."),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }
    
                            } else {
                                
                                Button(action: {
                                    UIPasteboard.general.string = FirebaseViewModel.shared.mail
                                    emailCopied = true
                                    
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    emailCopied = false
                                }
                                }) {
                                    HStack {
                                        Text("Reply")
                                        Image(systemName: "arrowshape.turn.up.right")
                                    }
                                    .padding()
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onAppear{
                                    print("isLoggedIn: \(FirebaseViewModel.shared.isLoggedIn)")
                                }
                                
                                if emailCopied {
                                    Text("Successfully copied the email!")
                                        .foregroundColor(.green)
                                        .transition(.opacity)
                                }
                                
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
                                                .destructive(Text("Block")) {
                                                    FirebaseViewModel.shared.blockCustomer(targetCustomerID: userID)
                                                },
                                                .cancel()
                                            ]
                                        )
                                    }
                                    
                                    /*
                                     
                                    .alert(isPresented: $confirmBlockAlert) {
                                        Alert(
                                            title: Text("Blocked the account."),
                                            message: Text(FirebaseViewModel.shared.blockSuccessMessage),
                                            dismissButton: .default(Text("OK")) {
                                                FirebaseViewModel.shared.blockSuccessMessage = ""
                                            }
                                        )
                                    }

                                    .actionSheet(isPresented: $localBlockSuccessSheet) {

                                        ActionSheet(title: Text("Successfully blocked!"), message: Text(FirebaseViewModel.shared.blockSuccessMessage), buttons: [.cancel(Text("OK")) { FirebaseViewModel.shared.blockSuccessMessage = "" }])
                                        
                                    }
                                    .actionSheet(isPresented: $localBlockFailureSheet) {

                                        ActionSheet(title: Text("Failed to block."), message: Text(FirebaseViewModel.shared.blockFailureMessage), buttons: [.cancel(Text("OK")){ FirebaseViewModel.shared.blockFailureMessage = "" }])
                                        
                                    }
                                     */

                                    
                                } else {}
                        
                            }
                            
                            Spacer()
                            
                        }
                        
                        ZStack(alignment: .topLeading) {
                            if FirebaseViewModel.shared.introductionText.isEmpty && !isEditingIntroduction {
                                if userID == Auth.auth().currentUser?.uid {
                                    Text("Write something about yourself...")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 5)
                                        .padding(.top, 8)
                                } else {
                                    Text("No introduction so far.")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 5)
                                        .padding(.top, 8)
                                }
                            }
                            
                            VStack {
                                if isEditingIntroduction {
                                    TextEditor(text: $newIntroductionText)
                                        .padding(4)
                                        .frame(height: 150)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(UIColor.separator), lineWidth: 1)
                                        )
                                        .cornerRadius(8)
                                } else {
                                    Text(FirebaseViewModel.shared.introductionText)
                                        .padding(4)

                                }
                                
                                if userID == Auth.auth().currentUser?.uid {
                                    Button(action: {
                                        if isEditingIntroduction {
                                            FirebaseViewModel.shared.updateIntroductionText(userID: userID, introduction: newIntroductionText)
                                        } else {
                                            newIntroductionText = FirebaseViewModel.shared.introductionText
                                        }
                                        isEditingIntroduction.toggle()
                                    }) {
                                        Text(isEditingIntroduction ? "Save" : "Edit")
                                    }
                                    .padding()
                                    .padding(.top, 20)
                                    .padding(.leading, 20)
                                }
                                
                                Spacer()
                                
                            }
                            .padding()
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    if userPostsViewModel.userPosts.isEmpty {
                        
                        if userID == Auth.auth().currentUser?.uid {
                            VStack {
                                Text("There is no post so far.")
                                    .padding()
                                NavigationLink(destination: Add3DModelView()) {
                                    Text("Post now →")
                                        .padding()
                                        .foregroundColor(Color.white)
                                        .cornerRadius(8)
                                }
                            }
                        } else {
                            
                            Text("There is no post so far.")
                                .padding()
                            
                        }
                        
                    } else {
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            
                            LazyHStack(spacing: 20) {
                                
                                ForEach(userPostsViewModel.userPosts) { post in
                                    
                                    NavigationLink(destination: DetailView(userID: post.creatorUserID, postID: post.id)) {
                                        
                                        VStack {
                                            if post.fileType == "mov" {
                                                
                                                AsyncImage(url: post.thumbnailURL) { phase in
                                                    switch phase {
                                                    case .success(let image):
                                                        image.resizable()
                                                            .aspectRatio(contentMode: .fit)
                                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                                            .frame(width: 400, height: 250)
                                                    case .failure(_), .empty:
                                                        EmptyView()
                                                    @unknown default:
                                                        EmptyView()
                                                    }
                                                }
                                                
                                                if let caption = post.caption {
                                                    Text(caption)
                                                        .lineLimit(3)
                                                        .truncationMode(.tail)
                                                        .padding(.top, 10)
                                                        .frame(width: 400)
                                                }
                                                
                                            } else if post.fileType == "usdz" || post.fileType == "reality" {
                                                
                                                Model3D(url: URL(string: post.videoURL)!) { model in
                                                    model
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                        .frame(width: 300, height: 187.5)
                                                } placeholder: {
                                                    ProgressView()
                                                }
                                                
                                                if let caption = post.caption {
                                                    Text(caption)
                                                        .lineLimit(3)
                                                        .truncationMode(.tail)
                                                        .padding(.top, 50)
                                                        .frame(width: 400)
                                                }
                                                
                                            }
                                            
                                        }
                                        .frame(width: 500, height: 312.5)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, 10)
                                }
                            }
                        }
                    }
                        
                    
                    Spacer()
                    
                    VStack {
                        
                        if userID == Auth.auth().currentUser?.uid {
                            
                            Text("We started to toddle only recently.")
                                .padding(.top, 20)
                            Text("If you have any concerns or request, please email us below.")
                            Spacer()
                            Text("support@teegarden.app")
                                .padding()
                                .padding(.bottom, 20)
                            
                        } else {
                            
                            Text("")
                                .padding()
                                .padding(.top, 20)
                                .padding(.bottom, 20)
                            
                        }
                        
                    }
                    .padding()
                    
                    Spacer()
                    
                }
                .padding(.top, 30)
                .padding(.bottom, 30)
                .padding(.leading, 30)
                .padding(.trailing, 30)
                .navigationTitle(userID == Auth.auth().currentUser?.uid ? "My Space" : "The Creator Profile")
                .navigationBarTitleDisplayMode(.inline)
                .sheet(isPresented: $showingImagePicker, onDismiss: handleImageSelectionForUpload) {
                    ImagePicker(selectedImage: $inputImage)
                }
            }
            .onAppear {
                
                fetchProfileImage(for: userID)
                userPostsViewModel.fetchUserPosts(userID: userID)
                FirebaseViewModel.shared.fetchUserProfile(userID: userID)
                FirebaseViewModel.shared.fetchIntroductionText(userID: userID)

            }
        }
    }
    
    func fetchProfileImage(for userID: String) {
        FirebaseViewModel.shared.fetchProfileImageURL(for: userID) { url in
            if let url = url {
                withAnimation {
                    profileImageURL = url
                }
            }
        }
    }
    
    func handleImageSelectionForUpload() {
        guard let userID = Auth.auth().currentUser?.uid, let imageToUpload = inputImage else { return }
        
        FirebaseViewModel.shared.uploadProfileImage(userID: userID, image: imageToUpload) { result in
            switch result {
            case .success(let url):
                print("Uploaded Profile Image URL: \(url)")
                FirebaseViewModel.shared.updateUserProfileImageURL(userID: userID, imageURL: url) { error in
                    if let error = error {
                        print("Error updating user profile with image URL: \(error.localizedDescription)")
                    } else {
                        print("User profile image URL updated successfully.")
                    }
                }
            case .failure(let error):
                print("Error uploading profile image: \(error.localizedDescription)")
            }
        }
    }
    
    func sendDeletionRequest() {
        let db = Firestore.firestore()
        let deletionRequestRef = db.collection("deletionRequest").document(userID)

        let requestData: [String: Any] = [
            "requestorCustomerID": userID,
            "requestDate": Timestamp(date: Date())
        ]

        deletionRequestRef.setData(requestData) { error in
            if let error = error {
                print("Error adding deletion request: \(error)")
            } else {
                print("Deletion request added successfully")
            }
        }
    }
    
}
