//
//  BreedDetailView.swift
//  Cats App
//
//  Created by Carlo André Aguilar on 18/10/25.
//

import SwiftUI
import SwiftData
import CachedAsyncImage

struct BreedDetailView: View {
    
    private let imageCornerRadius: CGFloat = 12
    @State private var viewModel: ViewModel
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                image
                if let descriptionText = viewModel.breed.descriptionText {
                    Text(descriptionText)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle(viewModel.breed.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var image: some View {
        Group {
            if let url = viewModel.breed.imageURL {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        emptyImageBackground
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .overlay(
                                /// Thin border around image, to make image shape visible when image background matches the app background.
                                RoundedRectangle(cornerRadius: imageCornerRadius)
                                    .stroke(Color.secondary, lineWidth: 1)
                            )
                    case .failure:
                        emptyImageBackground
                            .aspectRatio(1.0, contentMode: .fit)
                            .overlay {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.secondary)
                            }
                    default:
                        emptyImageBackground
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                }
            } else {
                emptyImageBackground
                    .aspectRatio(1.0, contentMode: .fit)
                    .overlay {
                        Text("No image")
                            .foregroundStyle(.secondary)
                    }
                
            }
        }
        .clipped()
        .cornerRadius(imageCornerRadius)
    }
    
    var emptyImageBackground: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.5))
    }
}

#Preview {
    let container = try! ModelContainer(for: CatBreed.self, configurations: .init(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    BreedDetailView(viewModel: BreedDetailView.DefaultViewModel(breed: .example, toggleFavouriteUseCase: .init(modelContext: context)))
}

