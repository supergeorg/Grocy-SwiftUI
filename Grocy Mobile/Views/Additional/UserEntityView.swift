//
//  UserEntityView.swift
//  Grocy-SwiftUI
//
//  Created by Georg Meissner on 22.01.21.
//

import SwiftUI

struct UserEntityView: View {
    var userEntity: MDUserEntity

    var body: some View {
        Text(userEntity.name)
    }
}

#Preview {
    UserEntityView(userEntity: MDUserEntity(id: 1, name: "recipesources", caption: "Recipe sources"))
}
