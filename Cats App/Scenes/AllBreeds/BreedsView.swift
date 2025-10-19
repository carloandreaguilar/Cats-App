//
//  BreedsView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 16/10/25.
//

import SwiftUI
import SwiftData

struct BreedsView: View {
    static let defaultTitle = "Cat breeds"
    
    @Environment(\.modelContext) var modelContext
    
    @State private var viewModel: ViewModel
    
    @Binding private var navigationPath: NavigationPath
    @State private var presentingOfflineAlert = false
    @State private var showingReconnectedToast = false
    
    @State private var scrollViewId = UUID()
    
    private let bannersHapticGenerator = UIImpactFeedbackGenerator(style: .soft)
    
    init(viewModel: ViewModel, navigationPath: Binding<NavigationPath>) {
        self.viewModel = viewModel
        self._navigationPath = navigationPath
    }
    
    var body: some View {
            Group {
                EmptyView()
                    .id("top")
                switch viewModel.viewState {
                case .loadingFirstPage:
                    VStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                case .loadingMore, .loaded:
                    ScrollView {
                        if viewModel.breeds.isEmpty {
                            ContentUnavailableView(
                                "No results",
                                systemImage: "cat.fill"
                            )
                            .foregroundStyle(Color.primary)
                        } else {
                           VStack(spacing: 0) {
                                    BreedsGridView(viewModel.breeds, onTap: { breed in
                                        navigationPath.append(BreedDestination.detail(breed: breed))
                                    }, onFavouriteTap: { breed in
                                        try? viewModel.toggleFavourite(for: breed)
                                    }, onlastItemAppear: {
                                        await viewModel.loadNextPageIfNeeded()
                                    })
                                    .animation({ if case .loaded = viewModel.viewState { return .default } else { return nil } }(), value: viewModel.viewState)
                                    footer()
                                }
                                .padding(.horizontal)
                            
                            
                        }
                    }
                    .id(scrollViewId)
                }
            }
            .overlay(alignment: .bottom) {
                Group {
                    switch viewModel.viewState {
                    case .loaded(let properties):
                        if properties.dataSourceMode == .offline {
                            offlineModeBanner()
                        } else if !properties.hasConnection {
                            noConnectionBanner()
                        } else if showingReconnectedToast {
                            reconnectedToast()
                        }
                    default:
                        EmptyView()
                    }
                }
                .animation(.default, value: viewModel.viewState)
                .animation(.default, value: showingReconnectedToast)
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
            .onChange(of: viewModel.viewState) { _, newValue in
                if case .loaded(let properties) = newValue, properties.isReload {
                    scrollViewId = UUID()
                }
            }
            .refreshable {
                let wasOffline: Bool = {
                    if case .loaded(let properties) = viewModel.viewState {
                        return properties.dataSourceMode == .offline
                    } else {
                        return false
                    }
                }()
                do {
                    try await viewModel.attemptNetworkRefresh()
                    if wasOffline {
                        showingReconnectedToast = true
                    }
                } catch {
                    if wasOffline {
                        presentingOfflineAlert = true
                    }
                }
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
            bannersHapticGenerator.prepare()
            bannersHapticGenerator.impactOccurred()
            Task { try? await viewModel.activateOfflineMode() }
        } label: {
            VStack {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text("No connection")
                        .font(.system(size: 16, weight: .bold))
                }
                Text("Tap to view saved data")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 2)
            }
            .padding(.vertical)
            .padding(.horizontal, 24)
            .glassEffect(.clear.tint(.red.opacity(0.75)), in: Capsule())
            .padding(.bottom)
        }
        .buttonStyle(.plain)
    }
    
    private func offlineModeBanner() -> some View {
        Button {
            bannersHapticGenerator.prepare()
            bannersHapticGenerator.impactOccurred()
            Task {
                do {
                    try await viewModel.attemptNetworkRefresh()
                    showingReconnectedToast = true
                } catch {
                    presentingOfflineAlert = true
                }
            }
        } label: {
            VStack {
                HStack {
                    Text("Offline mode is active")
                        .font(.system(size: 16, weight: .bold))
                }
                Text("Tap to reconnect")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.leading)
                    .padding(.bottom, 2)
            }
            .padding(.vertical)
            .padding(.horizontal, 24)
            .glassEffect(.clear.tint(.yellow.opacity(0.75)), in: Capsule())
            .padding(.bottom)
        }
        .buttonStyle(.plain)
    }
    
    private func reconnectedToast() -> some View {
        VStack {
            HStack {
                Text("Back online!")
                    .font(.system(size: 16, weight: .bold))
            }
        }
        .padding(.vertical)
        .padding(.horizontal, 24)
        .glassEffect(.clear.tint(.green.opacity(0.75)), in: Capsule())
        .padding(.bottom)
        .task {
            try? await Task.sleep(for: .seconds(3))
            showingReconnectedToast = false
        }
    }
    
    private func footer() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                switch viewModel.viewState {
                case .loadingMore:
                    ProgressView()
                default:
                    EmptyView()
                }
                Spacer()
            }
            Spacer()
        }
        .frame(height: AppConstants.View.scrollViewFooterHeight)
    }
    
    private func textIsEmpty(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

#Preview {
    let container = try! ModelContainer(for: CatBreed.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext

    BreedsView(
        viewModel: BreedsView.DefaultViewModel(
            breedsDataSource: DefaultBreedsDataSource(
                networkService: DefaultBreedsNetworkService(),
                persistenceService: DefaultBreedsPersistenceService(modelContext: context)
            ), toggleFavouriteUseCase: .init(modelContext: context)
        ), navigationPath: .constant(NavigationPath())
    )
    .modelContainer(container)
}

