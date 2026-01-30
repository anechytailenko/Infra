import SwiftUI

// MARK: - FolderDetailView
// Detail screen for a folder selected from HomeView. Shows graph (GraphView), file list with filter/sort, and history.

struct FolderDetailView: View {
    let folder: FolderNode?
    @StateObject private var viewModel: FolderDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSortPopover = false

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
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    #endif
                    sortBar
                    graphCard
                    FileListView(viewModel: viewModel)
                    HistoryListView(history: viewModel.history)
                }
                .padding(.horizontal, FolderDetailStyle.contentPaddingHorizontal)
                .padding(.top, FolderDetailStyle.contentPaddingTop)
                .padding(.bottom, FolderDetailStyle.contentPaddingBottom)
            }
        }
        .navigationTitle(folder.map { $0.name } ?? "Folder Details")
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

    private var sortBar: some View {
        HStack {
            Spacer()
            Button {
                showSortPopover = true
            } label: {
                Text("Sort")
                    .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                    .foregroundStyle(FolderDetailStyle.menuButtonIconColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: FolderDetailStyle.menuButtonCornerRadius).fill(FolderDetailStyle.menuButtonBackground))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSortPopover, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            viewModel.setSort(option)
                            showSortPopover = false
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .frame(minWidth: 120)
            }
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
