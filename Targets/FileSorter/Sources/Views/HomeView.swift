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
                    SearchView(searchText: $viewModel.searchQuery, exampleQuery: "file invoices", onSort: { Task { await viewModel.submitPrompt() } })
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
                .background(Group { })
                .navigationDestination(item: Binding(
                    get: { viewModel.selectedFolder },
                    set: { viewModel.selectedFolder = $0 }
                )) { folder in
                    FolderDetailView(folder: folder)
                }
                .navigationDestination(item: Binding(
                    get: { viewModel.promptNavigationItem },
                    set: { viewModel.promptNavigationItem = $0 }
                )) { item in
                    PromptView(
                        promptText: item.query,
                        matchedFiles: item.matchedFiles,
                        onDismiss: { viewModel.clearPromptResult() }
                    )
                }
                
                // Loading overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
                // Prompt loading overlay
                if viewModel.isPromptLoading {
                    promptLoadingOverlay
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
            .task {
                await viewModel.refreshOnAppear()
            }
        }
    }

    // MARK: - Graph Section

    private var graphSection: some View {
        ZStack {
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
    
    private var promptLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: AppStyle.textPrimary))
                
                Text("Searching files...")
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
