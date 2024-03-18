//
//  ViewModel.swift
//  booksp
//
//  Created by Takuzen Toh on 1/15/24.
//

import SwiftUI
import RealityKit
import Observation

@Observable
class ViewModel {

    var selectedType: SelectionType = .home
    var isShowingCube: Bool = false
    var targetSnapshot: UIImage?
    
    enum SelectionType: String, Identifiable, CaseIterable {
        case home = "home"
        case profile = "profile"
        case post = "post"
        case question = "support"

        var id: String {
            return rawValue
        }

        var title: String {
            switch self {
            case .home:
                return "Home"
            case .profile:
                return "Profile"
            case .post:
                return "Post"
            case .question:
                return "Support"
            }
        }

        var imageName: String {
            switch self {
            case .home:
                return "house"
            case .profile:
                return "person.crop.circle"
            case .post:
                return "plus"
            case .question:
                return "questionmark"
            }
        }
    }
    
    var showImmersiveSpace = false
    
    var privateOrPublic = false

    private var contentEntity = Entity()

    func setupContentEntity() -> Entity {
        contentEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        contentEntity.components.set(CollisionComponent(shapes: [ShapeResource.generateSphere(radius: 1E2)], isStatic: true))
        return contentEntity
    }

    func getTargetEntity(name: String) -> Entity? {
        return contentEntity.children.first { $0.name == name}
    }

    func addSpatialPlaceholder(name: String, value: EntityTargetValue<SpatialTapGesture.Value>?) -> ModelEntity {
        let entity = ModelEntity(
            mesh: .generatePlane(width: 0, depth: 0),
            materials: [SimpleMaterial(color: .white, isMetallic: false)],
            collisionShape: .generateBox(size: SIMD3<Float>(repeating: 0)),
            mass: 0.0
        )

        entity.name = name

        let pos = (value != nil) ? value!.convert(value!.location3D, from: .local, to: .scene) : SIMD3<Float>.zero
        entity.position = pos
        entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        entity.generateCollisionShapes(recursive: true)

        contentEntity.addChild(entity)

        return entity
    }

    func setEntityPosition(entity: ModelEntity, matrix: simd_float4x4) {
        let forward = simd_float3(0, 0, -1)
        let cameraForward = simd_act(matrix.rotation, forward)

        let front = SIMD3<Float>(x: cameraForward.x, y: cameraForward.y, z: cameraForward.z)
        let length: Float = 0.5
        let offset = length * simd_normalize(front)

        let position = SIMD3<Float>(x: matrix.position.x, y: matrix.position.y, z: matrix.position.z)

        entity.position = position + offset
        entity.orientation = matrix.rotation
    }
    
}
