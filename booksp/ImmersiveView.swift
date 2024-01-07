//
//  ImmersiveView.swift
//  booksp
//
//  Created by Takuzen Toh on 7/5/23.
//

// - Image Click => Amazon
// - Image Show Den
// - Image Moving

import SwiftUI
import RealityKit
import RealityKitContent
import Observation
import Foundation

/*

func getImageByUrl(url: String) -> UIImage{
    let url = URL(string: url)
    do {
        let data = try Data(contentsOf: url!)
        return UIImage(data: data)!
    } catch let err {
        print("Error : \(err.localizedDescription)")
    }
    return UIImage()
}

func getContentURL(url: String) -> URL{
    let url = URL(string: url)
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let data = try! Data(contentsOf: url!)
    try! data.write(to: fileURL)
    return fileURL
}

@Observable
class ImageViewModel {

    private let planeSize = CGSize(width: 0.32, height: 0.90)
    private let maxPlaneSize = CGSize(width: 3.0, height: 2.0)
    private var contentEntity = Entity()
//    private var contentEntity = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: [1,1]))
    private var images: [MaterialParameters.Texture] = []

    //https://books.google.com/books/content?id=uWhmDwAAQBAJ&printsec=frontcover&img=1
    
    func setupContentEntity(urls: [String]) -> Entity {
        images.removeAll()
        
        for var i in urls {
            let name = "laputa\(String(format: "%03d", i))"
            let insertIdx = i.index(i.startIndex, offsetBy: 4)
            i.insert(contentsOf: "s", at: insertIdx)
            let image:UIImage = getImageByUrl(url:i)
            if let texture = try? TextureResource.generate(
                from:image.cgImage!,
                withName: name,
                options: .init(semantic: .normal)
            ) {
                images.append(MaterialParameters.Texture(texture))
            }
        }
        setup()
        return contentEntity
    }
    
    // MARK: - Private
    private func setup() {
        if !contentEntity.children.isEmpty {
            contentEntity.children.removeAll()
        }
//        let boardPlane = ModelEntity(
//            mesh: .generatePlane(width: 0, height: 0),
//            materials: [SimpleMaterial(color: .clear, isMetallic: false)]
//        )
//        boardPlane.position = SIMD3<Float>(x: 0, y: 2, z: -0.5 - 0.1 * Float(1))
//        contentEntity.addChild(boardPlane)
//        addChildEntities(boardPlane: boardPlane)
        contentEntity.position = SIMD3<Float>(x: 0, y: 2, z: -0.5 - 0.1 * Float(1))
        var i: Int = 0
        for image in images.prefix(30) {
            let divisionResult = i.quotientAndRemainder(dividingBy: 5)
            let x: Float = Float(divisionResult.remainder) * 0.4 - 0.75
            let y: Float = Float(divisionResult.quotient) * 0.6 - 0.5
            let z: Float = contentEntity.position.z + 0.1 //+ Float(i) * 0.0001

            let entity = makeBook(
                name: "laputa\(String(format: "%03d", i))",
                posision: SIMD3<Float>(x: x, y: y, z: z),
                texture: image
            )
            contentEntity.addChild(entity)
            i += 1
        }
    }

    private func addChildEntities(boardPlane: ModelEntity) {
        var i: Int = 0
        for image in images.prefix(30) {
            let divisionResult = i.quotientAndRemainder(dividingBy: 5)
            let x: Float = Float(divisionResult.remainder) * 0.4 - 0.75
            let y: Float = Float(divisionResult.quotient) * 0.6 - 0.5
            let z: Float = boardPlane.position.z + 0.1 //+ Float(i) * 0.0001

            let entity = makeBook(
                name: "laputa\(String(format: "%03d", i))",
                posision: SIMD3<Float>(x: x, y: y, z: z),
                texture: image
            )
            boardPlane.addChild(entity)
            i += 1
        }
    }

    private func makeBook(
        name: String,
        posision: SIMD3<Float>,
        texture: MaterialParameters.Texture
    ) -> ModelEntity{
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        let tmp = "bookside"
        var bookSideMaterial = UnlitMaterial()
        if let texture = try? TextureResource.load(named: tmp) {
//            MaterialParameters.Texture(texture)
            bookSideMaterial.color = .init(texture: .init(texture))
        }
        let entity = ModelEntity(
            mesh: .generateBox(width: 0.32, height: 0.48, depth:0.06, cornerRadius: 0.0, splitFaces:true),
            materials: [material, bookSideMaterial, material, bookSideMaterial, UnlitMaterial(), UnlitMaterial()]
//            collisionShape: .generateBox(width: 0.32, height: 0.48, depth: 0.0),
//            mass: 0.0,
        )
        let size = entity.visualBounds(relativeTo: entity).extents
        let boxShape = ShapeResource.generateBox(size: size)
        entity.name = name
        entity.position = posision
        entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        entity.components.set(CollisionComponent(shapes: [boxShape], isStatic: true))
        return entity
    }
}
*/

struct ImmersiveView: View {
    
    //@State var model = ImageViewModel()
    @EnvironmentObject var viewModel: FirebaseViewModel
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        RealityView { content in
            
            let rootEntity = Entity()
            
            guard let texture = try? TextureResource.load(named: "pure-white-bg") else {
                return
            }
            var material = UnlitMaterial()
            material.color = .init(texture: .init(texture))
            rootEntity.components.set(ModelComponent(
                mesh: .generateSphere(radius: 1E3),
                materials: [material]
            ))
            rootEntity.scale *= .init(x: -1, y: 1, z: 1)
            rootEntity.transform.translation += SIMD3<Float>(0.0, 1.0, 0.0)
            
            content.add(rootEntity)
        }
    }
/*            debugPrint("called")
        } update: { content in
            debugPrint("update is called")
            debugPrint(content.entities.count)
            debugPrint(viewModel.favoriteBooks.map{
                $0.thumnailUrl
            })
//            content.remove(content.entities[2])
//            content.add(model.anchorEntity)
            content.add(
                model.setupContentEntity(
                    urls:viewModel.favoriteBooks.map{
                        $0.thumnailUrl
                    }
                )
            )
        }.onAppear{
            viewModel.getFavoriteBooks()
        }
        .gesture(tap)
        .gesture(dragGesture)
    }
    
    var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                debugPrint(value.location3D)
                debugPrint(value.entity)
                let entity = value.entity
                let convertedPos = value.convert(value.location3D, from: .local, to: entity.parent!)
                entity.position = SIMD3<Float>(x: convertedPos.x, y: convertedPos.y, z:convertedPos.z)
            }
    }
    
    var tap: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                debugPrint(value.entity)
                //sharedViewModel.setURL(hoge)
                openWindow(id: "webview")
            }
    }
*/
}

//#Preview {
//    ImmersiveView()
//        .previewLayout(.sizeThatFits)
//}
