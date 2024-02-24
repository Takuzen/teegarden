//
//  HomeView.swift
//  booksp
//
//  Created by Takuzen Toh on 2/24/24.
//

import SwiftUI
import RealityKit

struct HomeView: View {
    
    @StateObject private var homeViewModel = HomeViewModel()
    
    @State private var localFileURLs: [String: URL] = [:]
    @State private var fileURLs: [URL] = []
    @State private var profileImageURLs: [String: URL] = [:]
    
    func fetchProfileImage(for userID: String) {
        FirebaseViewModel.shared.fetchProfileImageURL(for: userID) { url in
            if let url = url {
                withAnimation {
                    profileImageURLs[userID] = url
                    print("profileImageURLs: \(profileImageURLs)")
                }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack {
                    Image("teegarden-logo-nobg")
                        .resizable()
                        .frame(width: 30, height: 30)
                    Text("Teegarden")
                        .font(.system(size: 25))
                    Spacer()
                }
                .padding(.leading, 15)
                .padding(.top, 40)
                
                VStack {
                    HStack {
                        Text("Spatial Creators")
                            .font(.headline)
                            .padding(.leading)
                        Spacer()
                    }
                    .padding(.top, 20)
                    .padding(.leading, 10)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        let rows = [GridItem(.flexible(minimum: 10, maximum: .infinity), spacing: 20)]
                        
                        LazyHGrid(rows: rows, spacing: 20) {
                            
                            ForEach(homeViewModel.homePosts) { post in
                                
                                NavigationLink(destination: DetailView(userID: post.creatorUserID, postID: post.id)) {
                                    
                                    VStack {
                                        
                                        NavigationLink(destination: UserView(userID: post.creatorUserID, username: post.username)) {
                                            HStack {
                                                if let profileImageURL = profileImageURLs[post.creatorUserID] {
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
                                                
                                                Text(post.username)
                                                    .bold()
                                                    .padding(.leading, 5)
                                                
                                                Spacer()
                                            }
                                            .padding(.bottom, 25)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .frame(width: 600)
                                        
                                        switch post.fileType {
                                        case "mov":
                                            if let thumbnailURL = post.thumbnailURL {
                                                ZStack(alignment: .topTrailing) {
                                                    AsyncImage(url: thumbnailURL) { phase in
                                                        switch phase {
                                                        case .success(let image):
                                                            image.resizable()
                                                                .scaledToFill()
                                                                .frame(width: 600, height: 247.22)
                                                                .clipped()
                                                                .transition(.opacity)
                                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                        case .failure(_), .empty:
                                                            EmptyView()
                                                        @unknown default:
                                                            EmptyView()
                                                        }
                                                    }
                                                    .padding(.top, 5)
                                                    .padding(.trailing, 5)
                                                    
                                                    Image(systemName: "pano.badge.play.fill")
                                                        .symbolRenderingMode(.palette)
                                                        .imageScale(.large)
                                                        .padding([.top, .trailing], 20)
                                                }
                                            } else {
                                                
                                                Text("No thumbnail available")
                                                    .frame(width: 600, height: 247.22)
                                                    .background(Color.gray.opacity(0.5))
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    .shadow(radius: 10)
                                                    .padding(.top, 30)
                                                    .padding(.bottom, 30)
                                                
                                            }
                                        case "usdz", "reality":
                                            ZStack(alignment: .topTrailing) {
                                                
                                                Model3D(url: URL(string: post.videoURL)!) { model in
                                                    model
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                } placeholder: {
                                                    ProgressView()
                                                }
                                                .frame(width: 540, height: 187.22)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .padding(.top, 55)
                                                .padding(.bottom, 55)
                                                
                                                Image(systemName: "move.3d")
                                                    .symbolRenderingMode(.palette)
                                                    .imageScale(.large)
                                                    .padding([.top, .trailing], 20)
                                                
                                            }
                                        default:
                                            Text("Unsupported or no preview available")
                                                .frame(width: 600, height: 247.22)
                                                .background(Color.gray.opacity(0.5))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        
                                        if let caption = post.caption, !caption.isEmpty {
                                            Text(caption)
                                                .lineLimit(3)
                                                .truncationMode(.tail)
                                                .frame(maxWidth: 500, alignment: .leading)
                                                .padding(.top, 20)
                                        }

                                    }
                                    .onAppear {
                                        // Debug statement to print post details
                                        print("Post ID: \(post.id), Username: \(post.username), Caption: \(post.caption ?? "No caption")")
                                    }
                                }
                                .frame(width: 600, height: 800)
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        .frame(height: geometry.size.height / 1.5)
                        
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height / 3 * 2 + 100)
                    .padding(.leading, 30)
                    .padding(.top, -30)
                    
                }
                .onAppear {
                    print("Fetching posts...")
                    homeViewModel.fetchHomePosts {
                        print("Posts fetched: \(FirebaseViewModel.shared.homePosts.count)")
                        for post in FirebaseViewModel.shared.homePosts {
                            print("Post ID: \(post.id), Username: \(post.username)")
                            fetchProfileImage(for: post.creatorUserID)
                        }
                        print("Posts: \(FirebaseViewModel.shared.homePosts)")
                    }
                }
                
                Spacer()
                
            }
        }
    }
}
