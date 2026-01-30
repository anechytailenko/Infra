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
                            destination: SearchResultsStubView(query: viewModel.searchResultsQuery ?? "", onDismiss: { viewModel.clearSearchResults() }),
                            isActive: Binding(
                                get: { viewModel.searchResultsQuery != nil },
                                set: { if !$0 { viewModel.clearSearchResults() } }
                            )
                        ) { EmptyView() }
                        .hidden()
                    }
                )
                // Modern navigation pattern: destination created only when item is non-nil
                .navigationDestination(item: Binding(
                    get: { viewModel.selectedFolder },
                    set: { viewModel.selectedFolder = $0 }
                )) { folder in
                    FolderDetailView(folder: folder)
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("Retry") {
                    Task { await viewModel.retryFetch() }
                }
                Button("Dismiss", role: .cancel) {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred.")
            }
            .task(id: viewModel.selectedFolder?.id) {
                // Poll backend when at root: first load (selectedFolder nil) or when returning (selectedFolder becomes nil again)
                await viewModel.refreshOnAppear()
            }
        }
    }

    // MARK: - Graph Section

    private var graphSection: some View {
        ZStack {
            // Folders are only clickable when data is available from API
            // No Accept/Decline HUD needed on HomeView, enable hover animation
            GraphView(
                root: viewModel.rootNode,
                onFolderSelected: viewModel.isDataAvailable ? { viewModel.selectFolder($0) } : nil,
                showHUD: false,
                enableHoverAnimation: true
            )
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
            
            // Inline error state (recoverable errors)
            if let errorMessage = viewModel.errorMessage, !viewModel.showErrorAlert {
                inlineErrorView(message: errorMessage)
            }
        }
        .background(AppStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius))
        .shadow(color: AppStyle.cardShadowColor, radius: AppStyle.cardShadowRadius, x: AppStyle.cardShadowX, y: AppStyle.cardShadowY)
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: AppStyle.textPrimary))
                
                Text("Loading filesystem...")
                    .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                    .foregroundStyle(AppStyle.cardBackground)
            }
            .padding(30)
            .background(RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius).fill(Color.black.opacity(0.6)))
        }
    }
    
    // MARK: - Inline Error View
    
    private func inlineErrorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(AppStyle.textSecondary)
            
            Text(message)
                .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                .foregroundStyle(AppStyle.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                Task { await viewModel.retryFetch() }
            } label: {
                Text("Retry")
                    .font(.system(size: AppStyle.bodyFontSize, weight: .medium))
                    .foregroundStyle(AppStyle.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppStyle.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppStyle.textSecondary.opacity(0.3), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(AppStyle.cardBackground.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius))
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
