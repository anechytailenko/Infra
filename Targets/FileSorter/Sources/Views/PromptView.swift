import SwiftUI

// MARK: - PromptView
// Displays matched files from the prompt API with a folder graph and file list.

struct PromptView: View {
    @StateObject private var viewModel: PromptViewModel
    @Environment(\.dismiss) private var dismiss
    
    /// Closure called when the view should be dismissed
    let onDismiss: (() -> Void)?
    
    /// Accent color for prompt-specific highlights (prompt chip, folder name badge)
    private let accentColor = AppStyle.folderIconColor
    
    // MARK: - Initialization
    
    init(promptText: String, matchedFiles: [String], onDismiss: (() -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: PromptViewModel(
            promptText: promptText,
            matchedPaths: matchedFiles
        ))
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Navigation Header
            HStack(spacing: AppStyle.backButtonHStackSpacing) {
                Button(action: {
                    onDismiss?()
                    dismiss()
                }) {
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
                
                HStack(spacing: 8) {
                    Text("Prompt:")
                        .font(.system(size: AppStyle.bodyFontSize, weight: .bold))
                        .foregroundStyle(AppStyle.textPrimary)
                    
                    Text(viewModel.userPrompt)
                        .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accentColor.opacity(AppStyle.nodeFillOpacity))
                        .clipShape(RoundedRectangle(cornerRadius: AppStyle.backButtonCornerRadius))
                }
                
                Spacer()
            }
            .padding(.horizontal, GraphViewStyle.mainPadding)
            .padding(.vertical, 16)
            .background(AppStyle.cardBackground)
            .overlay(
                Rectangle()
                    .frame(height: AppStyle.titleBarSeparatorHeight)
                    .foregroundStyle(AppStyle.titleBarSeparatorColor),
                alignment: .bottom
            )
            
            // MARK: - Top Section: Graph Visualization
            ZStack {
                AppStyle.cardBackground
                
                if let root = viewModel.rootNode {
                    GraphView(
                        root: root,
                        onFolderSelected: nil,
                        highlightedFolderNames: viewModel.highlightedFolderNames
                    )
                } else {
                    ProgressView("Loading Graph...")
                        .foregroundStyle(AppStyle.textSecondary)
                }
            }
            .frame(height: 450)
            .overlay(
                Rectangle()
                    .frame(height: AppStyle.titleBarSeparatorHeight)
                    .foregroundStyle(AppStyle.titleBarSeparatorColor),
                alignment: .bottom
            )
            
            // MARK: - Bottom Section: Matched Files List
            PromptFileListView(viewModel: viewModel, accentColor: accentColor)
        }
        .background(AppStyle.screenBackground)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - PromptFileListView

struct PromptFileListView: View {
    @ObservedObject var viewModel: PromptViewModel
    let accentColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack(spacing: 12) {
                
                Text(viewModel.folderName)
                    .font(.system(size: AppStyle.bodyFontSize, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(accentColor.opacity(AppStyle.nodeFillOpacity))
                    .clipShape(RoundedRectangle(cornerRadius: AppStyle.backButtonCornerRadius))
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { viewModel.toggleSelectAll() }) {
                        Text(viewModel.isAllSelected ? "Deselect All" : "Select All")
                            .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                            .foregroundStyle(accentColor)
                    }
                    .buttonStyle(.plain)
                    
                    Text("Selected: \(viewModel.selectedCount)")
                        .font(.system(size: AppStyle.bodyFontSize))
                        .foregroundStyle(AppStyle.textSecondary)
                    
                    Button(action: { viewModel.deleteSelected() }) {
                        Label("Remove", systemImage: "trash")
                            .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                            .foregroundStyle(AppStyle.cardBackground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.selectedCount == 0)
                    .opacity(viewModel.selectedCount == 0 ? 0.5 : 1.0)
                }
            }
            .padding(.horizontal, GraphViewStyle.mainPadding)
            .padding(.vertical, 16)
            .background(AppStyle.cardBackground)
            
            Rectangle()
                .frame(height: AppStyle.titleBarSeparatorHeight)
                .foregroundStyle(AppStyle.titleBarSeparatorColor)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.files.enumerated()), id: \.element.id) { index, file in
                        PromptFileRow(
                            file: file,
                            index: index,
                            isActive: viewModel.activeFile?.id == file.id,
                            accentColor: accentColor
                        ) {
                            viewModel.toggleSelection(for: file.id)
                        }
                        .onTapGesture {
                            withAnimation {
                                viewModel.setActiveFile(file)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(AppStyle.cardBackground)
        }
    }
}

// MARK: - PromptFileRow

struct PromptFileRow: View {
    let file: PromptFile
    let index: Int
    let isActive: Bool
    let accentColor: Color
    let onToggle: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: file.isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundStyle(file.isSelected ? accentColor : AppStyle.textSecondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            Text(file.name)
                .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                .foregroundStyle(AppStyle.textPrimary)
            
            Spacer()
            
            Text(file.size)
                .font(.system(size: AppStyle.bodyFontSize))
                .foregroundStyle(AppStyle.textSecondary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, GraphViewStyle.mainPadding)
        .padding(.vertical, 10)
        .background(
            isActive ? accentColor.opacity(0.1) :
                (isHovering ? accentColor.opacity(0.05) :
                    (index % 2 == 0 ? AppStyle.screenBackground.opacity(0.5) : AppStyle.cardBackground))
        )
        .onHover { hover in
            isHovering = hover
        }
    }
}
