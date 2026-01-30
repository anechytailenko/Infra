import SwiftUI

// MARK: - HomeView
// Container that includes SearchView and GraphView.

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    // State for pan/zoom gestures (UI-only)
    @State private var offset: CGSize = .zero
    @State private var lastDragPosition: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                AppStyle.screenBackground
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    titleBarPane
                    SearchView(searchText: $viewModel.searchQuery, exampleQuery: "file invoices", onSort: { viewModel.submitSearch() })
                    Text("Select any folder to arrange files✨")
                        .font(AppStyle.headlineFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppStyle.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, GraphViewStyle.mainPadding)
                        .padding(.top, GraphViewStyle.titleTopPadding)
                        .padding(.bottom, GraphViewStyle.titleBottomPadding)
                    graphSection
                        .padding(GraphViewStyle.mainPadding)
                }
                .background(
                    Group {
                        NavigationLink(
                            destination: FolderDetailView(folder: viewModel.selectedFolder),
                            isActive: Binding(
                                get: { viewModel.selectedFolder != nil },
                                set: { if !$0 { viewModel.clearFolderSelection() } }
                            )
                        ) { EmptyView() }
                        .hidden()
                        NavigationLink(
                            destination: SearchResultsStubView(query: viewModel.searchResultsQuery ?? "", onDismiss: { viewModel.clearSearchResults() }),
                            isActive: Binding(
                                get: { viewModel.searchResultsQuery != nil },
                                set: { if !$0 { viewModel.clearSearchResults() } }
                            )
                        ) { EmptyView() }
                        .hidden()
                    }
                )
            }
        }
    }

    // MARK: - Graph Section

    private var graphSection: some View {
        GraphView(root: viewModel.rootNode, onFolderSelected: { viewModel.selectFolder($0) })
            .scaleEffect(scale)
            .offset(x: offset.width, y: offset.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .gesture(
                SimultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastDragPosition.width + value.translation.width,
                                height: lastDragPosition.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastDragPosition = offset
                        },
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = lastScale * value
                            scale = max(GraphViewStyle.zoomMin, min(GraphViewStyle.zoomMax, newScale))
                        }
                        .onEnded { _ in
                            lastScale = scale
                        }
                )
            )
            .background(AppStyle.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius))
            .shadow(color: AppStyle.cardShadowColor, radius: AppStyle.cardShadowRadius, x: AppStyle.cardShadowX, y: AppStyle.cardShadowY)
    }

    private var titleBarPane: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: AppStyle.titleBarHeight)
                .frame(maxWidth: .infinity)
                .background(AppStyle.titleBarBackground)
            Rectangle()
                .fill(AppStyle.titleBarSeparatorColor)
                .frame(height: AppStyle.titleBarSeparatorHeight)
                .shadow(
                    color: AppStyle.titleBarSeparatorShadowColor,
                    radius: AppStyle.titleBarSeparatorShadowRadius,
                    x: 0,
                    y: AppStyle.titleBarSeparatorShadowY
                )
        }
    }
}
