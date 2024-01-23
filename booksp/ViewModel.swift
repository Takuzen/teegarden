//
//  ViewModel.swift
//  booksp
//
//  Created by Takuzen Toh on 1/15/24.
//

import SwiftUI
import Observation

@Observable
class ViewModel {

    var selectedType: SelectionType = .guitars
    var isShowingCube: Bool = false
    
    enum SelectionType: String, Identifiable, CaseIterable {
        case guitars = "guitars"
        case shoes = "shoes"

        var id: String {
            return rawValue
        }

        var url: URL {
            switch self {
            case .guitars:
                return URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/stratocaster/fender_stratocaster.usdz")!
            case .shoes:
                return URL(string: "https://developer.apple.com/augmented-reality/quick-look/models/nike-air-force/sneaker_airforce.usdz")!
            }
        }

        var title: String {
            switch self {
            case .guitars:
                return "Profile"
            case .shoes:
                return "Post"
            }
        }

        var imageName: String {
            switch self {
            case .guitars:
                return "person.crop.circle"
            case .shoes:
                return "plus"
            }
        }
    }

}
