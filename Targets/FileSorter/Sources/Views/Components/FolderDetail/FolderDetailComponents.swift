import SwiftUI

// MARK: - FileListView
// File list with filter/sort bar and rows. Uses FolderDetailStyle and AppStyle.

struct FileListView: View {
    @ObservedObject var viewModel: FolderDetailViewModel
    @State private var showFilterPopover = false
    @State private var filterButtonHover = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: FolderDetailStyle.listHeaderHStackSpacing) {
                Image(systemName: "doc.text")
                    .foregroundStyle(AppStyle.textSecondary)
                Text("User")
                    .font(AppStyle.headlineFont)
                    .foregroundStyle(AppStyle.textPrimary)
                Spacer()
                HStack(spacing: FolderDetailStyle.filterSortBarSpacing) {
                    Button {
                        showFilterPopover = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(FolderDetailStyle.menuButtonIconColor)
                            .frame(width: FolderDetailStyle.filterSortButtonSize, height: FolderDetailStyle.filterSortButtonSize)
                            .background(RoundedRectangle(cornerRadius: FolderDetailStyle.menuButtonCornerRadius).fill(FolderDetailStyle.menuButtonBackground))
                            .opacity(filterButtonHover ? 1 : FolderDetailStyle.buttonHoverOpacityNormal)
                    }
                    .buttonStyle(.plain)
                    .onHover { filterButtonHover = $0 }
                    .popover(isPresented: $showFilterPopover, arrowEdge: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Button {
                                viewModel.toggleShowFiles()
                                showFilterPopover = false
                            } label: {
                                if viewModel.showFiles { Label("Files", systemImage: "checkmark") } else { Text("Files") }
                            }
                            .buttonStyle(.plain)
                            Button {
                                viewModel.toggleShowFolders()
                                showFilterPopover = false
                            } label: {
                                if viewModel.showFolders { Label("Folders", systemImage: "checkmark") } else { Text("Folders") }
                            }
                            .buttonStyle(.plain)
                            Divider()
                            ForEach(FilterOption.allCases, id: \.self) { option in
                                Button(option.rawValue) {
                                    viewModel.setFilter(option)
                                    showFilterPopover = false
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(12)
                        .frame(minWidth: 160)
                    }
                }
            }
            .padding(.horizontal, FolderDetailStyle.listRowPaddingHorizontal)
            .padding(.vertical, FolderDetailStyle.listRowPaddingVertical)
            .background(AppStyle.cardBackground)
            Rectangle()
                .fill(AppStyle.textPrimary.opacity(FolderDetailStyle.listDividerOpacity))
                .frame(height: 1)
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.filteredAndSortedFiles.isEmpty {
                        Text("No files")
                            .font(.system(size: AppStyle.bodyFontSize))
                            .foregroundStyle(AppStyle.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, FolderDetailStyle.listRowPaddingVertical)
                    } else {
                        ForEach(viewModel.filteredAndSortedFiles) { file in
                            FileRowView(file: file)
                            Rectangle()
                                .fill(AppStyle.textPrimary.opacity(FolderDetailStyle.listDividerOpacity))
                                .frame(height: 1)
                                .padding(.leading, FolderDetailStyle.listDividerLeadingPadding)
                        }
                    }
                }
            }
        }
        .frame(height: viewModel.filteredAndSortedFiles.isEmpty ? FolderDetailStyle.fileListHeightEmpty : FolderDetailStyle.fileListHeight)
        .background(AppStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FolderDetailStyle.listCornerRadius))
        .shadow(color: AppStyle.cardShadowColor, radius: AppStyle.cardShadowRadius, x: AppStyle.cardShadowX, y: AppStyle.cardShadowY)
    }
}

// MARK: - FileRowView

struct FileRowView: View {
    let file: FileItem

    var body: some View {
        HStack(alignment: .center, spacing: FolderDetailStyle.listRowHStackSpacing) {
            Image(systemName: file.iconName)
                .font(.system(size: FolderDetailStyle.listRowIconSize))
                .foregroundStyle(AppStyle.textSecondary)
                .frame(width: 24)
            Text(file.name)
                .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                .foregroundStyle(AppStyle.textPrimary)
            Spacer()
            HStack(spacing: 20) {
                Text(file.formattedSize).frame(width: 60, alignment: .trailing)
                Text(file.formattedType).frame(width: 80, alignment: .leading)
                Text(file.formattedDate).frame(width: 100, alignment: .trailing)
            }
            .font(.system(size: 12))
            .foregroundStyle(AppStyle.textSecondary)
        }
        .padding(.horizontal, FolderDetailStyle.listRowPaddingHorizontal)
        .padding(.vertical, FolderDetailStyle.listRowPaddingVertical)
        .background(AppStyle.cardBackground)
    }
}

// MARK: - HistoryListView

struct HistoryListView: View {
    let history: [HistoryItem]
    var onRevertLast: (() -> Void)? = nil
    @State private var revertButtonHover = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: FolderDetailStyle.listHeaderHStackSpacing) {
                Image(systemName: "clock")
                    .foregroundStyle(AppStyle.textSecondary)
                Text("History")
                    .font(AppStyle.headlineFont)
                    .foregroundStyle(AppStyle.textPrimary)
                Spacer()
                if let onRevertLast = onRevertLast {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            onRevertLast()
                        }
                    } label: {
                        Text("Revert last")
                            .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                            .foregroundStyle(FolderDetailStyle.menuButtonIconColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: FolderDetailStyle.menuButtonCornerRadius).fill(FolderDetailStyle.menuButtonBackground))
                            .opacity(revertButtonHover ? 1 : FolderDetailStyle.buttonHoverOpacityNormal)
                    }
                    .buttonStyle(.plain)
                    .onHover { revertButtonHover = $0 }
                }
            }
            .padding(.horizontal, FolderDetailStyle.listRowPaddingHorizontal)
            .padding(.vertical, FolderDetailStyle.listRowPaddingVertical)
            .background(AppStyle.cardBackground)
            Rectangle()
                .fill(AppStyle.textPrimary.opacity(FolderDetailStyle.listDividerOpacity))
                .frame(height: 1)
            ForEach(history) { item in
                HStack(spacing: FolderDetailStyle.listRowHStackSpacing) {
                    ZStack {
                        Circle()
                            .stroke(FolderDetailStyle.historySuccessColor.opacity(FolderDetailStyle.historySuccessBorderOpacity), lineWidth: 1)
                            .background(Circle().fill(FolderDetailStyle.historySuccessColor.opacity(FolderDetailStyle.historySuccessFillOpacity)))
                            .frame(width: FolderDetailStyle.historyIconSize, height: FolderDetailStyle.historyIconSize)
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(FolderDetailStyle.historySuccessColor)
                    }
                    .frame(width: 24)
                    Text(item.status)
                        .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                        .foregroundStyle(AppStyle.textPrimary)
                    Spacer()
                    Text(item.date)
                        .font(.system(size: 12))
                        .foregroundStyle(AppStyle.textSecondary)
                }
                .padding(.horizontal, FolderDetailStyle.listRowPaddingHorizontal)
                .padding(.vertical, FolderDetailStyle.listRowPaddingVertical)
                .background(AppStyle.cardBackground)
                .transition(.opacity.combined(with: .move(edge: .top)))
                if item.id != history.last?.id {
                    Rectangle()
                        .fill(AppStyle.textPrimary.opacity(FolderDetailStyle.listDividerOpacity))
                        .frame(height: 1)
                        .padding(.leading, FolderDetailStyle.listDividerLeadingPadding)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: history.count)
        .background(AppStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FolderDetailStyle.listCornerRadius))
        .shadow(color: AppStyle.cardShadowColor, radius: AppStyle.cardShadowRadius, x: AppStyle.cardShadowX, y: AppStyle.cardShadowY)
    }
}
