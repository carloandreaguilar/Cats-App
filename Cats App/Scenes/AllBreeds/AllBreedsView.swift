//
//  AllBreedsView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI

struct AllBreedsView: View {
    static let defaultTitle = "All Breeds"
    
    @State private var viewModel: ViewModel
    
    @State private var searchText = ""
    
    init(viewModel: ViewModel = DefaultViewModel()) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Group {
            switch viewModel.viewState {
            case .loadingFirstPage:
                VStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            case .loadingMore, .loaded:
                ScrollView {
                    VStack {
                        BreedsGridView(viewModel.breeds, onlastItemAppear: viewModel.loadNextPageIfNeeded)
                            .animation({ if case .loaded = viewModel.viewState { return .default } else { return nil } }(), value: viewModel.viewState)
                        footer
                            .padding(.vertical)
                    }
                    .padding(.horizontal)
                }
            case .error:
                EmptyView()
            }
        }
        .searchable(text: $searchText)
        .refreshable {
            await viewModel.loadFirstPage()
        }
        .task {
            if viewModel.breeds.isEmpty {
                await viewModel.loadFirstPage()
            }
        }
    }
    
    var footer: some View {
        HStack {
            Spacer()
            switch viewModel.viewState {
            case .loadingMore:
                ProgressView()
            case .loaded(let hasMore):
                if !hasMore {
                    Text(viewModel.breeds.isEmpty ? "No results" : "Showing all results")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            default:
                EmptyView()
            }
            Spacer()
        }
    }
}

#Preview {
    AllBreedsView(viewModel: AllBreedsView.DefaultViewModel())
}
