 
 
 struct homeView: View {
    @ObservedObject var firebaseViewModel = FirebaseViewModel()
    
    @State private var fileURLs: [URL] = []
    
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    let customColor = Color(red: 0.988, green: 0.169, blue: 0.212)
    
    
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
                .padding(.leading, 10)
                .padding(.top, 40)
                
                VStack {
                    HStack {
                        Text("Spatial Videos")
                            .font(.headline)
                            .padding(.leading)
                        Spacer()
                    }
                    .padding([.top, .leading], 10)
                    
                    Spacer()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        let rows = [GridItem(.flexible(minimum: 10, maximum: .infinity), spacing: 20)]
                        
                        LazyHGrid(rows: rows, spacing: 20) {
                            ForEach(firebaseViewModel.spatialVideoMetadataArray, id: \.thumbnailURL) { metadata in
                                NavigationLink(destination: DetailView()) {
                                    VStack {
                                        HStack {
                                            if let profileImageURL = firebaseViewModel.userProfileImageURL {
                                                AsyncImage(url: profileImageURL) { phase in
                                                    if let image = phase.image {
                                                        image.resizable()
                                                            .aspectRatio(contentMode: .fill)
                                                    } else if phase.error != nil {
                                                        Image(systemName: "person.circle") // If an error occurred during image loading
                                                            .resizable()
                                                            .frame(width: 40, height: 40)
                                                            .clipShape(Circle())
                                                    } else {
                                                        Image(systemName: "person.circle") // Placeholder for loading state
                                                            .resizable()
                                                            .frame(width: 40, height: 40)
                                                            .clipShape(Circle())
                                                    }
                                                }
                                                .scaledToFit()
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                            } else {
                                                Image(systemName: "person.circle")
                                                    .resizable()
                                                    .frame(width: 30, height: 30)
                                                    .clipShape(Circle())
                                            }
                                            
                                            Text(firebaseViewModel.username)
                                                .padding(.leading, 5)
                                            
                                            Spacer()
                                        }
                                        .padding(.bottom, 20)
                                        
                                        AsyncImage(url: URL(string: metadata.thumbnailURL)) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 600, height: 247.22)
                                                    .clipped()
                                                    .transition(.opacity)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                            } else if phase.error != nil {
                                                Color.red
                                            } else {
                                                ZStack {
                                                    Color.gray
                                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                                    
                                                    VStack {
                                                        Spacer()
                                                        HStack {
                                                            ProgressView()
                                                                .frame(width: 840, height: 500)
                                                                .clipped()
                                                        }
                                                        Spacer()
                                                    }
                                                }
                                            }
                                        }
                                        
                                        if let caption = metadata.caption {
                                            Text(caption)
                                                .padding(.top, 20)
                                        }
                                    }
                                }
                                .frame(width: 600, height: 800)
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 10)
                        .frame(width: geometry.size.width, height: geometry.size.height / 1.5)
                        
                        Spacer()
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height / 3 * 2 + 100)
                    .onAppear {
                        firebaseViewModel.fetchThumbnailsMetadata() { result in
                            switch result {
                            case .success(let thumbnails):
                                print("Successfully fetched thumbnails: \(thumbnails)")
                            case .failure(let error):
                                print("Error fetching thumbnails: \(error)")
                            }
                        }
                    }
                    .onReceive(timer) { _ in
                        firebaseViewModel.fetchThumbnailsMetadata() { result in
                            switch result {
                            case .success(let thumbnails):
                                print("Successfully fetched thumbnails: \(thumbnails)")
                            case .failure(let error):
                                print("Error fetching thumbnails: \(error)")
                            }
                        }
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}
