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
        case home = "home"
        case guitars = "guitars"
        case shoes = "shoes"

        var id: String {
            return rawValue
        }

        var title: String {
            switch self {
            case .home:
                return "Home"
            case .guitars:
                return "Profile"
            case .shoes:
                return "Post"
            }
        }

        var imageName: String {
            switch self {
            case .home:
                return "house"
            case .guitars:
                return "person.crop.circle"
            case .shoes:
                return "plus"
            }
        }
    }

}
