//
//  AllBreedsView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI
import SwiftData

struct AllBreedsView: View {
    static let defaultTitle = "All Breeds"
    
    @Environment(\.modelContext) var modelContext
    
    @State private var viewModel: ViewModel
    
    @Binding private var navigationPath: NavigationPath
    
    @State private var searchText = ""
    
    init(viewModel: ViewModel, navigationPath: Binding<NavigationPath>) {
        self.viewModel = viewModel
        self._navigationPath = navigationPath
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
                        BreedsGridView(viewModel.breeds, onTap: { breed in
                            navigationPath.append(BreedDestination.detail(breed: breed))
                        }, onFavouriteTap: { breed in
                            try? viewModel.toggleFavourite(for: breed)
                        }, onlastItemAppear: {
                            await viewModel.loadNextPageIfNeeded()
                        })
                        .animation({ if case .loaded = viewModel.viewState { return .default } else { return nil } }(), value: viewModel.viewState)
                        footer()
                            .padding(.vertical)
                    }
                    .padding(.horizontal)
                }
                .overlay(alignment: .bottom) {
                    if case .loaded(_, let dataSourceType) = viewModel.viewState, dataSourceType == .offline {
                        offlineBanner()
                    }
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
        .navigationDestination(for: BreedDestination.self, destination: { destination in
            switch destination {
            case .detail(let breed):
                BreedDetailView(viewModel: BreedDetailView.DefaultViewModel(breed: breed, toggleFavouriteUseCase: .init(modelContext: modelContext)))
            }
        })
    }
    
    private func offlineBanner() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("Offline")
                .font(.footnote.weight(.semibold))
        }
        .padding(12)
        .glassEffect(.regular, in: Capsule())
        .padding(.bottom, 12)
    }
    
    func footer() -> some View {
        HStack {
            Spacer()
            switch viewModel.viewState {
            case .loadingMore:
                ProgressView()
            case .loaded(let hasMore, _):
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
    let container = try! ModelContainer(for: CatBreed.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext

    AllBreedsView(
        viewModel: AllBreedsView.DefaultViewModel(
            breedsDataSource: DefaultBreedsDataSource(
                networkService: DefaultBreedsNetworkService(),
                persistenceService: DefaultBreedsPersistenceService(modelContext: context)
            ), toggleFavouriteUseCase: .init(modelContext: context)
        ), navigationPath: .constant(NavigationPath())
    )
    .modelContainer(container)
}
