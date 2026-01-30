import SwiftUI

// #region agent log
private func _debugLog(_ message: String, location: String, hypothesisId: String, data: [String: String] = [:]) {
    let path = "/Users/hermanhavva/Documents/Personal/projects/FileSorterApp/.cursor/debug.log"
    var parts = ["\"message\":\"\(message.replacingOccurrences(of: "\"", with: "\\\""))\"", "\"location\":\"\(location)\"", "\"hypothesisId\":\"\(hypothesisId)\"", "\"timestamp\":\(Int(Date().timeIntervalSince1970 * 1000))"]
    if !data.isEmpty {
        let dataStr = data.map { "\"\($0.key)\":\"\($0.value)\"" }.joined(separator: ",")
        parts.append("\"data\":{\(dataStr)}")
    }
    let line = "{" + parts.joined(separator: ",") + "}\n"
    guard let d = line.data(using: .utf8) else { return }
    if FileManager.default.fileExists(atPath: path) {
        if let h = try? FileHandle(forUpdating: URL(fileURLWithPath: path)) {
            h.seekToEndOfFile()
            h.write(d)
            try? h.close()
        }
    } else {
        FileManager.default.createFile(atPath: path, contents: d, attributes: nil)
    }
}
// #endregion

// MARK: - FileListView
// File list with filter/sort bar and rows. Uses FolderDetailStyle and AppStyle.

struct FileListView: View {
    @ObservedObject var viewModel: FolderDetailViewModel
    @State private var showFilterPopover = false
    @State private var showSortPopover = false
    @State private var showOptionsPopover = false

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
                    }
                    .buttonStyle(.plain)
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
                    Button {
                        showSortPopover = true
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(FolderDetailStyle.menuButtonIconColor)
                            .frame(width: FolderDetailStyle.filterSortButtonSize, height: FolderDetailStyle.filterSortButtonSize)
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
                    Button {
                        showOptionsPopover = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(FolderDetailStyle.menuButtonIconColor)
                            .frame(width: FolderDetailStyle.filterSortButtonSize, height: FolderDetailStyle.filterSortButtonSize)
                            .background(RoundedRectangle(cornerRadius: FolderDetailStyle.menuButtonCornerRadius).fill(FolderDetailStyle.menuButtonBackground))
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showOptionsPopover, arrowEdge: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Button("Refresh") { showOptionsPopover = false }
                                .buttonStyle(.plain)
                            Button("Export…") { showOptionsPopover = false }
                                .buttonStyle(.plain)
                        }
                        .padding(12)
                        .frame(minWidth: 120)
                    }
                }
                // #region agent log
                .background(GeometryReader { g in
                    Color.clear.onAppear {
                        _debugLog("trailing HStack size", location: "FileListView:menus", hypothesisId: "H5", data: ["width": "\(g.size.width)", "height": "\(g.size.height)"])
                    }
                })
                // #endregion
            }
            // #region agent log
            .background(GeometryReader { g in
                Color.clear.onAppear {
                    _debugLog("FileList header size", location: "FileListView:header", hypothesisId: "H2", data: ["width": "\(g.size.width)", "height": "\(g.size.height)"])
                }
            })
            // #endregion
            .padding(.horizontal, FolderDetailStyle.listRowPaddingHorizontal)
            .padding(.vertical, FolderDetailStyle.listRowPaddingVertical)
            .background(AppStyle.cardBackground)
            Rectangle()
                .fill(AppStyle.textPrimary.opacity(FolderDetailStyle.listDividerOpacity))
                .frame(height: 1)
            ForEach(viewModel.filteredAndSortedFiles) { file in
                FileRowView(file: file)
                Rectangle()
                    .fill(AppStyle.textPrimary.opacity(FolderDetailStyle.listDividerOpacity))
                    .frame(height: 1)
                    .padding(.leading, FolderDetailStyle.listDividerLeadingPadding)
            }
        }
        .background(AppStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FolderDetailStyle.listCornerRadius))
        .shadow(color: AppStyle.cardShadowColor, radius: AppStyle.cardShadowRadius, x: AppStyle.cardShadowX, y: AppStyle.cardShadowY)
        // #region agent log
        .onAppear {
            _debugLog("FileListView body appeared", location: "FileListView:body", hypothesisId: "H4", data: ["buttonSize": "\(FolderDetailStyle.filterSortButtonSize)", "platform": ProcessInfo.processInfo.operatingSystemVersionString, "runId": "post-fix"])
        }
        // #endregion
    }
}

// MARK: - FileRowView

struct FileRowView: View {
    let file: FileItem

    var body: some View {
        HStack(alignment: .center, spacing: FolderDetailStyle.listRowHStackSpacing) {
            Image(systemName: file.iconName)
                .font(.system(size: 20))
                .foregroundStyle(AppStyle.textSecondary)
                .frame(width: 30)
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
    @State private var showMenuPopover = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: FolderDetailStyle.listHeaderHStackSpacing) {
                Image(systemName: "clock")
                    .foregroundStyle(AppStyle.textSecondary)
                Text("History")
                    .font(AppStyle.headlineFont)
                    .foregroundStyle(AppStyle.textPrimary)
                Spacer()
                Button {
                    showMenuPopover = true
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(FolderDetailStyle.menuButtonIconColor)
                        .frame(width: FolderDetailStyle.filterSortButtonSize, height: FolderDetailStyle.filterSortButtonSize)
                        .background(RoundedRectangle(cornerRadius: FolderDetailStyle.menuButtonCornerRadius).fill(FolderDetailStyle.menuButtonBackground))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showMenuPopover, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Button("Sort by date") { showMenuPopover = false }
                            .buttonStyle(.plain)
                        Button("Clear history") { showMenuPopover = false }
                            .buttonStyle(.plain)
                    }
                    .padding(12)
                    .frame(minWidth: 120)
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
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(FolderDetailStyle.historySuccessColor)
                    }
                    .frame(width: 30)
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
                if item.id != history.last?.id {
                    Rectangle()
                        .fill(AppStyle.textPrimary.opacity(FolderDetailStyle.listDividerOpacity))
                        .frame(height: 1)
                        .padding(.leading, FolderDetailStyle.listDividerLeadingPadding)
                }
            }
        }
        .background(AppStyle.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FolderDetailStyle.listCornerRadius))
        .shadow(color: AppStyle.cardShadowColor, radius: AppStyle.cardShadowRadius, x: AppStyle.cardShadowX, y: AppStyle.cardShadowY)
        // #region agent log
        .onAppear {
            _debugLog("HistoryListView body appeared", location: "HistoryListView:body", hypothesisId: "H4", data: ["buttonSize": "\(FolderDetailStyle.filterSortButtonSize)"])
        }
        // #endregion
    }
}
