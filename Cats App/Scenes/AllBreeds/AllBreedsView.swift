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
    @State private var presentingOfflineAlert = false
    
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
            default:
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
                    switch viewModel.viewState {
                    case .loaded(_, let hasConnection, let dataSourceMode):
                        if dataSourceMode == .offline {
                            offlineModeBanner()
                        } else if !hasConnection {
                            noConnectionBanner()
                        }
                    default:
                        EmptyView()
                    }
                }
            }
        }
        .searchable(text: $viewModel.query)
        .onSubmit(of: .search) {
            Task { try? await viewModel.loadFirstPage() }
            
        }
        .onChange(of: viewModel.query) { oldValue, newValue in
            if !textIsEmpty(oldValue) && textIsEmpty(newValue) {
                Task { try? await viewModel.loadFirstPage() }
            }
        }
        .refreshable {
            try? await viewModel.loadFirstPage()
        }
        .task {
            if viewModel.breeds.isEmpty {
                try? await viewModel.loadFirstPage()
            }
        }
        .navigationDestination(for: BreedDestination.self, destination: { destination in
            switch destination {
            case .detail(let breed):
                BreedDetailView(viewModel: BreedDetailView.DefaultViewModel(breed: breed, toggleFavouriteUseCase: .init(modelContext: modelContext)))
            }
        })
        .alert(isPresented: $presentingOfflineAlert) {
            Alert(
                title: Text("Still offline"),
                message: Text("Check your connection and try again."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func noConnectionBanner() -> some View {
        Button {
            Task { try? await viewModel.activateOfflineMode() }
        } label: {
            VStack {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text("No connection")
                        .font(.footnote.weight(.semibold))
                }
                Text("Tap to view offline data")
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .glassEffect(.regular, in: Capsule())
            .padding(.bottom)
            .foregroundStyle(.red)
        }
        .buttonStyle(.plain)
    }
    
    private func offlineModeBanner() -> some View {
        Button {
            Task {
                do {
                    try await viewModel.attemptReconnect()
                } catch {
                    presentingOfflineAlert = true
                }
            }
        } label: {
            VStack {
                HStack {
                    Text("Offline mode active")
                        .font(.footnote.weight(.semibold))
                }
                Text("Tap to reconnect")
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .glassEffect(.regular, in: Capsule())
            .padding(.bottom)
        }
        .buttonStyle(.plain)
    }
    
    private func footer() -> some View {
        HStack {
            Spacer()
            switch viewModel.viewState {
            case .loadingMore:
                ProgressView()
            case .loaded(let hasMore, _, _):
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
    
    private func textIsEmpty(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

