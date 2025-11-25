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
    
    @State private var viewModel: BreedsViewModel
    @State private var scrollViewId = UUID()
    @Environment(\.appDependencies) private var appDependencies
    private let bannersHapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    init(viewModel: BreedsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            switch viewModel.viewState {
            case .loadingFirstPage:
                emptyLoadingView()
            case .loaded:
                if viewModel.breeds.isEmpty {
                    contentUnavailableView()
                } else {
                    breedsScrollableGrid()
                }
            }
        }
        .animation(.default, value: viewModel.viewState != .loadingFirstPage)
        .searchable(text: $viewModel.query)
        .onSubmit(of: .search) {
            Task { try? await viewModel.loadFirstPage() }
            
        }
        .onChange(of: viewModel.query) { oldValue, newValue in
            if textWasCleared(newValue: newValue, oldValue: oldValue) {
                Task { try? await viewModel.loadFirstPage() }
            }
        }
        .onChange(of: viewModel.viewState) { _, newValue in
            if case .loaded(let properties) = newValue, properties.isReload {
                scrollViewId = UUID()
            }
        }
        .refreshable {
            try? await viewModel.attemptNetworkRefresh()
        }
        .task {
            if viewModel.breeds.isEmpty {
                try? await viewModel.loadFirstPage()
            }
            bannersHapticGenerator.prepare()
        }
        .navigationDestination(for: BreedDestination.self, destination: { destination in
            switch destination {
            case .detail(let breed):
                BreedDetailView(viewModel: appDependencies.makeDetailViewModel(breed: breed))
            }
        })
        .overlay(alignment: .bottom) {
            ZStack {
                if !viewModel.hasConnection && viewModel.dataSourceMode == .online {
                    noConnectionBanner()
                }
                if viewModel.dataSourceMode == .offline {
                    offlineModeBanner()
                }
                if viewModel.showingReconnectedToast {
                    reconnectedToast()
                }
            }
            .animation(.default, value: viewModel.hasConnection)
            .animation(.default, value: viewModel.dataSourceMode == .offline)
            .animation(.default, value: viewModel.showingReconnectedToast)
        }
        .alert(isPresented: $viewModel.presentingOfflineAlert) {
            Alert(
                title: Text("Still offline"),
                message: Text("Check your connection and try again."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func breedsScrollableGrid() -> some View {
        ScrollView {
            VStack(spacing: 0) {
                BreedsGridView(viewModel.breeds, onTap: { breed in
                    viewModel.navigationPath.wrappedValue.append(BreedDestination.detail(breed: breed))
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
        .id(scrollViewId)
    }
    
    private func contentUnavailableView() -> some View {
        ContentUnavailableView(
            "No results",
            systemImage: "cat.fill"
        )
        .foregroundStyle(Color.primary)
    }
    
    private func emptyLoadingView() -> some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }
    
    private func noConnectionBanner() -> some View {
        Button {
            triggerBannersHapticFeedback()
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
        .buttonStyle(BouncePressStyle())
        .fixedSize()
        .accessibilityIdentifier("noConnectionBanner")
    }
    
    private func offlineModeBanner() -> some View {
        Button {
            triggerBannersHapticFeedback()
            viewModel.animatingOfflineBanner = true
            Task {
                do {
                    try await viewModel.attemptNetworkRefresh()
                    showReconnectedToast()
                } catch {
                    viewModel.presentingOfflineAlert = true
                }
                viewModel.animatingOfflineBanner = false
            }
        } label: {
            ZStack(alignment: .center) {
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
                .opacity(viewModel.animatingOfflineBanner ? 0 : 1)
                if viewModel.animatingOfflineBanner {
                    ProgressView()
                }
            }
            .padding(.vertical)
            .padding(.horizontal, 24)
            .glassEffect(.clear.tint(.yellow.opacity(0.75)), in: Capsule())
            .animation(.default, value: viewModel.animatingOfflineBanner)
            .padding(.bottom)
        }
        .buttonStyle(BouncePressStyle())
        .disabled(viewModel.animatingOfflineBanner)
        .fixedSize()
        .accessibilityIdentifier("offlineModeBanner")
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    viewModel.showingReconnectedToast = false
                }
            }
        }
        .fixedSize()
        .accessibilityIdentifier("reconnectedToast")
        .animation(.default, value: viewModel.showingReconnectedToast)
    }
    
    private func footer() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                if case .loaded(properties: let properties) = viewModel.viewState, properties.loadingMore {
                    ProgressView()
                } else {
                    EmptyView()
                }
                Spacer()
            }
            Spacer()
        }
        .frame(height: AppConstants.ViewLayout.scrollViewBottomPadding)
    }
    
    private func showReconnectedToast() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                viewModel.showingReconnectedToast = true
            }
        }
    }
    
    private func textWasCleared(newValue: String, oldValue: String) -> Bool {
        return newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !oldValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func triggerBannersHapticFeedback() {
        bannersHapticGenerator.prepare()
        bannersHapticGenerator.impactOccurred()
    }
}

#Preview {
    let container = try! ModelContainer(for: CatBreed.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    BreedsView(
        viewModel: DefaultBreedsViewModel(
            breedsDataSource: DefaultBreedsDataSource(
                networkService: DefaultBreedsNetworkService(),
                persistenceService: DefaultBreedsPersistenceService(modelContext: context)
            ), toggleFavouriteUseCase: DefaultToggleFavouriteUseCase(modelContext: context), navigationPath: .constant(NavigationPath())
        )
    )
    .modelContainer(container)
}

