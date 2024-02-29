//
//  HomeView.swift
//  booksp
//
//  Created by Takuzen Toh on 2/24/24.
//

import SwiftUI
import RealityKit
import FirebaseFirestore

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
    
    func timeAgo(from timestamp: Timestamp?) -> String {
        guard let timestamp = timestamp else { return "Unknown" }
        let postDate = timestamp.dateValue()
        let currentDate = Date()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: postDate, to: currentDate)

        if let years = components.year, years > 0 {
            return years == 1 ? "1 year ago" : "\(years) years ago"
        } else if let months = components.month, months > 0 {
            return months == 1 ? "1 month ago" : "\(months) months ago"
        } else if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else if let seconds = components.second, seconds > 0 {
            return seconds == 1 ? "1 second ago" : "\(seconds) seconds ago"
        } else {
            return "Just now"
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
                .padding(.bottom, 30)
                    
                    NavigationStack {
                        
                        HStack{
                            Text("Recently")
                                .padding(.leading, 20)
                                .padding(.bottom, 20)
                                .bold()
                            Spacer()
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            
                            let rows = [GridItem(.flexible(minimum: 10, maximum: .infinity), spacing: 20)]
                            
                            LazyHGrid(rows: rows, spacing: 20) {
                                
                                ForEach(homeViewModel.homePosts.sorted(by: {
                                    ($0.creationDate ?? Date.distantPast) > ($1.creationDate ?? Date.distantPast)
                                }), id: \.id) { post in
                                        
                                    VStack {
                                        // Head Part
                                        VStack {
                                            
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
                                                    .buttonStyle(PlainButtonStyle())
                                                }
                                            }
                                            
                                        }
                                        .frame(width: 600, height: 80)
                                        
                                        // Main Part
                                        VStack {
                                            
                                            NavigationLink(destination: DetailView(userID: post.creatorUserID, postID: post.id)) {
                                                
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
                                                
                                            }
                                        }
                                        .frame(width: 600, height: 200)
                                        
                                        // Foot Part
                                        VStack {
                                            
                                            HStack {
                                                Spacer()
                                                Image(systemName: "visionpro")
                                                Text("\(post.views)")
                                                Image(systemName: "clock")
                                                Text("\(timeAgo(from: post.timestamp))")
                                            }
                                            .padding(.trailing, 20)
                                            
                                            
                                            HStack {
                                                
                                                if let caption = post.caption, !caption.isEmpty {
                                                    Text(caption)
                                                        .lineLimit(2)
                                                        .truncationMode(.tail)
                                                        .frame(width: 560, height: 50, alignment: .leading)
                                                        .padding(.leading, 20)
                                                        .padding(.trailing, 20)
                                                }
                                                
                                            }
                                            
                                        }
                                        .frame(width: 600, height: 100)
                                        .padding(.top, 20)
                                    }
                                    .frame(width: 600, height: 800)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxHeight: 400)
            
                    }
                    .onAppear {
                        homeViewModel.fetchHomePosts {
                            for post in homeViewModel.homePosts {
                                fetchProfileImage(for: post.creatorUserID)
                            }
                        }
                    }
                }
                .padding(.leading, 30)
                .frame(width: geometry.size.width, height: geometry.size.height / 3 * 2 + 100)
            }
        
        }
    }
