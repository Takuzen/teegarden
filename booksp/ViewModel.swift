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

    var selectedType: SelectionType = .home
    var isShowingCube: Bool = false
    
    enum SelectionType: String, Identifiable, CaseIterable {
        case home = "home"
        case profile = "profile"
        case post = "post"

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
            }
        }
    }

}
