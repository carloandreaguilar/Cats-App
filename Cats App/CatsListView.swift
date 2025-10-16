//
//  CatsListView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI

struct CatsListView: View {
    static let defaultTitle = "All Breeds"
    
    @State private var searchText = ""
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
            .searchable(text: $searchText)
    }
}

#Preview {
    CatsListView()
}
