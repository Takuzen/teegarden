//
//  ImmersiveView.swift
//  booksp
//
//  Created by Takuzen Toh on 7/5/23.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Observation
import Foundation

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
    private var boardPlanes: [ModelEntity] = []
    private var images: [MaterialParameters.Texture] = []
    private var sorted = true

    //https://books.google.com/books/content?id=uWhmDwAAQBAJ&printsec=frontcover&img=1
    
    func setupContentEntity(urls: [String]) -> Entity {
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
//            if let texture = try? TextureResource.load(
//                contentsOf: getContentURL(url: i)
//            ) {
//                images.append(MaterialParameters.Texture(texture))
//            }
        }
        setup()
        return contentEntity
    }
    
    // MARK: - Private

    private func setup() {
        let boardPlane = ModelEntity(
            mesh: .generatePlane(width: 3, height: 2),
            materials: [SimpleMaterial(color: .clear, isMetallic: false)]
        )
        boardPlane.position = SIMD3<Float>(x: 0, y: 2, z: -0.5 - 0.1 * Float(1))
        contentEntity.addChild(boardPlane)
        boardPlanes.append(boardPlane)
        addChildEntities(boardPlane: boardPlane)
    }

    private func addChildEntities(boardPlane: ModelEntity) {
        var i: Int = 0
        for image in images.shuffled().prefix(30) {
            let divisionResult = i.quotientAndRemainder(dividingBy: 5)
            let x: Float = Float(divisionResult.remainder) * 0.4 - 0.75
            let y: Float = Float(divisionResult.quotient) * 0.6 - 0.5
            let z: Float = boardPlane.position.z + 0.1 //+ Float(i) * 0.0001

            let entity = makePlane(
                name: "laputa\(String(format: "%03d", i))",
                posision: SIMD3<Float>(x: x, y: y, z: z),
                texture: image
            )
            boardPlane.addChild(entity)
            i += 1
        }
    }

    private func makePlane(
        name: String,
        posision: SIMD3<Float>,
        texture: MaterialParameters.Texture
    ) -> ModelEntity{
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
//        material.metallic = .float(1.0)
        let entity = ModelEntity(
            mesh: .generatePlane(width: 0.32, height: 0.48, cornerRadius: 0.0),
            materials: [material]
//            collisionShape: .generateBox(width: 0.32, height: 0.48, depth: 0.0),
//            mass: 0.0
        )
        entity.name = name
        entity.position = posision
        entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        return entity
    }
}

struct ImmersiveView: View {
    @State var model = ImageViewModel()
    @EnvironmentObject var viewModel: FirebaseViewModel
    
    var body: some View {
        RealityView { content in
            // Add the initial RealityKit content
            if let immersiveContentEntity = try? await Entity(named: "DenModelWood", in: realityKitContentBundle) {
                content.add(immersiveContentEntity)

                // Add an ImageBasedLight for the immersive content
                if let imageBasedLightURL = Bundle.main.url(forResource: "ImageBasedLight", withExtension: "exr"),
                   let imageBasedLightImageSource = CGImageSourceCreateWithURL(imageBasedLightURL as CFURL, nil),
                   let imageBasedLightImage = CGImageSourceCreateImageAtIndex(imageBasedLightImageSource, 0, nil),
                   let imageBasedLightResource = try? await EnvironmentResource.generate(fromEquirectangular: imageBasedLightImage) {
                    let imageBasedLightSource = ImageBasedLightComponent.Source.single(imageBasedLightResource)

                    let imageBasedLight = Entity()
                    imageBasedLight.components.set(ImageBasedLightComponent(source: imageBasedLightSource))
                    content.add(imageBasedLight)

                    immersiveContentEntity.components.set(ImageBasedLightReceiverComponent(imageBasedLight: imageBasedLight))
                }

                // Put skybox here.  See example in World project available at
                // https://developer.apple.com/
            }
            content.add(
                model.setupContentEntity(
                    urls:viewModel.favoriteBooks.map{
                        $0.thumnailUrl
                    }
                )
            )
            debugPrint("called")
        }.onAppear{
            viewModel.getFavoriteBooks()
        }
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
