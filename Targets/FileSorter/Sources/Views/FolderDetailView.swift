import SwiftUI

// MARK: - FolderDetailView
// Detail screen for a folder selected from HomeView. Shows graph (GraphView), file list with filter/sort, and history.

struct FolderDetailView: View {
    let folder: FolderNode?
    @StateObject private var viewModel: FolderDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var backButtonHover = false
    @State private var sortButtonHover = false
    @State private var cancelButtonHover = false
    @State private var offset: CGSize = .zero
    @State private var lastDragPosition: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    init(folder: FolderNode? = nil) {
        self.folder = folder
        _viewModel = StateObject(wrappedValue: FolderDetailViewModel(folder: folder))
    }

    var body: some View {
        ZStack {
            FolderDetailStyle.detailBackground
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: FolderDetailStyle.sectionSpacing) {
                    #if os(macOS)
                    HStack {
                        Button { dismiss() } label: {
                            HStack(spacing: AppStyle.backButtonHStackSpacing) {
                                Image(systemName: AppStyle.backButtonIcon)
                                    .font(AppStyle.backButtonFont)
                                Text(AppStyle.backButtonLabel)
                                    .font(AppStyle.backButtonFont)
                            }
                            .foregroundStyle(AppStyle.backButtonForegroundColor)
                            .padding(.horizontal, AppStyle.backButtonPaddingHorizontal)
                            .padding(.vertical, AppStyle.backButtonPaddingVertical)
                            .opacity(backButtonHover ? 1 : FolderDetailStyle.buttonHoverOpacityNormal)
                        }
                        .buttonStyle(.plain)
                        .onHover { backButtonHover = $0 }
                        Spacer()
                    }
                    #endif
                    sortBar
                    graphCard
                    FileListView(viewModel: viewModel)
                    HistoryListView(history: viewModel.history, onRevertLast: { viewModel.revertLast() })
                }
                .padding(.horizontal, FolderDetailStyle.contentPaddingHorizontal)
                .padding(.top, FolderDetailStyle.contentPaddingTop)
                .padding(.bottom, FolderDetailStyle.contentPaddingBottom)
            }
            
            // Loading overlay when AI sort is in progress
            if viewModel.isSortingInProgress {
                sortLoadingOverlay
            }
        }
        .background(
            NavigationLink(
                destination: sortDecisionDestination,
                isActive: Binding(
                    get: { viewModel.shouldNavigateToSortDecision },
                    set: { viewModel.shouldNavigateToSortDecision = $0 }
                )
            ) { EmptyView() }
            .hidden()
        )
        .navigationTitle(folder.map { $0.name } ?? "Folder Details")
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("Retry") {
                viewModel.startAISort()
            }
            Button("Dismiss", role: .cancel) {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: AppStyle.backButtonHStackSpacing) {
                        Image(systemName: AppStyle.backButtonIcon)
                            .font(AppStyle.backButtonFont)
                        Text(AppStyle.backButtonLabel)
                            .font(AppStyle.backButtonFont)
                    }
                    .foregroundStyle(AppStyle.backButtonForegroundColor)
                }
            }
        }
        #endif
    }

    private var sortLoadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: AppStyle.textPrimary))
                
                Text("Preparing sort...")
                    .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                    .foregroundStyle(AppStyle.cardBackground)
                
                Button { viewModel.cancelAISort() } label: {
                    Text("Cancel")
                        .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                        .foregroundStyle(FolderDetailStyle.menuButtonIconColor)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: FolderDetailStyle.menuButtonCornerRadius).fill(AppStyle.cardBackground))
                        .opacity(cancelButtonHover ? 1 : FolderDetailStyle.buttonHoverOpacityNormal)
                }
                .buttonStyle(.plain)
                .onHover { cancelButtonHover = $0 }
            }
            .padding(30)
            .background(RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius).fill(Color.black.opacity(0.6)))
        }
    }
    
    private var sortBar: some View {
        HStack {
            Spacer()
            Button { viewModel.startAISort() } label: {
                Text("AI Sort")
                    .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                    .foregroundStyle(FolderDetailStyle.menuButtonIconColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: FolderDetailStyle.menuButtonCornerRadius).fill(FolderDetailStyle.menuButtonBackground))
                    .opacity(sortButtonHover ? 1 : FolderDetailStyle.buttonHoverOpacityNormal)
            }
            .buttonStyle(.plain)
            .onHover { sortButtonHover = $0 }
        }
    }

    /// Destination view for sort decision, initialized with AI response if available
    @ViewBuilder
    private var sortDecisionDestination: some View {
        if let aiResponse = viewModel.aiSuggestionsResponse {
            SortDecisionView(aiResponse: aiResponse)
        } else {
            SortDecisionView()
        }
    }
    
    private var graphCard: some View {
        GraphView(root: viewModel.folderGraphRoot, onFolderSelected: nil)
            .scaleEffect(scale)
            .offset(x: offset.width, y: offset.height)
            .frame(minHeight: FolderDetailStyle.graphCardMinHeight)
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
                        .onEnded { _ in lastDragPosition = offset },
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = lastScale * value
                            scale = max(GraphViewStyle.zoomMin, min(GraphViewStyle.zoomMax, newScale))
                        }
                        .onEnded { _ in lastScale = scale }
                )
            )
            .padding(GraphViewStyle.graphAreaPadding)
            .background(AppStyle.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.cardCornerRadius))
            .shadow(color: AppStyle.cardShadowColor, radius: AppStyle.cardShadowRadius, x: AppStyle.cardShadowX, y: AppStyle.cardShadowY)
    }
}
