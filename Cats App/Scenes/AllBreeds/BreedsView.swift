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
    
    @Binding private var navigationPath: NavigationPath
    @State private var presentingOfflineAlert = false
    @State private var showingReconnectedToast = false
    @State private var showingNoConnectionBanner = false
    @State private var showingOfflineModeBanner = false
    @State private var animatingOfflineBanner = false
    
    @State private var scrollViewId = UUID()
    
    @Environment(\.appDependencies) private var appDependencies
    
    private let bannersHapticGenerator = UIImpactFeedbackGenerator(style: .soft)
    
    init(viewModel: BreedsViewModel, navigationPath: Binding<NavigationPath>) {
        self.viewModel = viewModel
        self._navigationPath = navigationPath
    }
    
    var body: some View {
            Group {
                switch viewModel.viewState {
                case .loadingFirstPage:
                    emptyLoadingView()
                case .loadingMore, .loaded:
                    if viewModel.breeds.isEmpty {
                        contentUnavailableView()
                    } else {
                        breedsScrollableGrid()
                    }
                }
            }
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
                if case .loaded(let properties) = newValue {
                    if properties.isReload {
                        scrollViewId = UUID()
                    }
                    withAnimation {
                        showingNoConnectionBanner = !properties.hasConnection && properties.dataSourceMode == .online
                        showingOfflineModeBanner = properties.dataSourceMode == .offline
                    }
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
                        showReconnectedToast()
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
                    BreedDetailView(viewModel: appDependencies.makeDetailViewModel(breed: breed))
                }
            })
            .overlay(alignment: .bottom) {
                if showingNoConnectionBanner {
                    noConnectionBanner()
                }
            }
            .overlay(alignment: .bottom) {
                if showingOfflineModeBanner {
                    offlineModeBanner()
                }
            }
            .overlay(alignment: .bottom) {
                if showingReconnectedToast {
                    reconnectedToast()
                }
            }
            .alert(isPresented: $presentingOfflineAlert) {
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
        .buttonStyle(BouncePressStyle())
        .fixedSize()
        .accessibilityIdentifier("noConnectionBanner")
    }
    
    private func offlineModeBanner() -> some View {
        Button {
            bannersHapticGenerator.prepare()
            bannersHapticGenerator.impactOccurred()
            animatingOfflineBanner = true
            Task {
                do {
                    try await viewModel.attemptNetworkRefresh()
                    showReconnectedToast()
                } catch {
                    presentingOfflineAlert = true
                }
                animatingOfflineBanner = false
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
                .opacity(animatingOfflineBanner ? 0 : 1)
                if animatingOfflineBanner {
                    ProgressView()
                }
            }
            .padding(.vertical)
            .padding(.horizontal, 24)
            .glassEffect(.clear.tint(.yellow.opacity(0.75)), in: Capsule())
            .padding(.bottom)
        }
        .buttonStyle(BouncePressStyle())
        .disabled(animatingOfflineBanner)
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showingReconnectedToast = false
                }
            }
        }
        .fixedSize()
        .accessibilityIdentifier("reconnectedToast")
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
        .frame(height: AppConstants.ViewLayout.scrollViewBottomPadding)
    }
    
    private func showReconnectedToast() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                showingReconnectedToast = true
            }
        }
    }
    
    private func textWasCleared(newValue: String, oldValue: String) -> Bool {
        return newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !oldValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
            ), toggleFavouriteUseCase: DefaultToggleFavouriteUseCase(modelContext: context)
        ), navigationPath: .constant(NavigationPath())
    )
    .modelContainer(container)
}
