import SwiftUI

struct PromptView: View {
    @StateObject private var viewModel = PromptViewModel()
    
    private let highlightPurple = Color(red: 0.4, green: 0.1, blue: 0.8)
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - Navigation Header
            HStack(spacing: 16) {
                Button(action: { }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                }
                .buttonStyle(.plain)
                
                HStack(spacing: 8) {
                    Text("Prompt:")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(viewModel.userPrompt)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(highlightPurple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(highlightPurple.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.1)),
                alignment: .bottom
            )
            
            // MARK: - Top Section: Graph Visualization
            ZStack {
                Color.white
                
                if let root = viewModel.rootNode {
                    GraphView(
                        root: root,
                        startDepth: 0,
                        // NEW: Pass the active file state
                        activeFile: viewModel.activeFile,
                        activeFileParentName: viewModel.activeFile.flatMap { viewModel.getParentFolder(for: $0) },
                        onAccept: { print("User Accepted Sort") },
                        onDecline: { print("User Declined Sort") }
                    )
                } else {
                    ProgressView("Loading Graph...")
                }
            }
            .frame(height: 450)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .bottom
            )
            
            // MARK: - Bottom Section: Matched Files List
            PromptFileListView(viewModel: viewModel, highlightColor: highlightPurple)
        }
        .background(Color.white)
        .ignoresSafeArea()
    }
}

struct PromptFileListView: View {
    @ObservedObject var viewModel: PromptViewModel
    let highlightColor: Color
    
    var body: some View {
        VStack(spacing: 0) {
            
            HStack(spacing: 12) {
                
                Text(viewModel.folderName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(highlightColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(highlightColor.opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: { viewModel.toggleSelectAll() }) {
                        Text(viewModel.isAllSelected ? "Deselect All" : "Select All")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    
                    Text("Selected: \(viewModel.selectedCount)")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Button(action: { viewModel.deleteSelected() }) {
                        Label("Remove", systemImage: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.selectedCount == 0)
                    .opacity(viewModel.selectedCount == 0 ? 0.5 : 1.0)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.files.enumerated()), id: \.element.id) { index, file in
                        PromptFileRow(file: file, index: index, isActive: viewModel.activeFile?.id == file.id) {
                            // Checkbox Action
                            viewModel.toggleSelection(for: file.id)
                        }
                        // NEW: Tap on row sets active file for graph
                        .onTapGesture {
                            withAnimation {
                                viewModel.setActiveFile(file)
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

struct PromptFileRow: View {
    let file: PromptFile
    let index: Int
    let isActive: Bool // NEW: Is this the file shown in graph?
    let onToggle: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: file.isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundColor(file.isSelected ? .blue : .gray.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            Text(file.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
            
            Spacer()
            
            Text(file.size)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        // Background Logic: Active(Green tint) > Hover(Blue tint) > Stripe(Grey/White)
        .background(
            isActive ? Color.green.opacity(0.1) :
            (isHovering ? Color.blue.opacity(0.05) :
            (index % 2 == 0 ? Color.gray.opacity(0.08) : Color.white))
        )
        .onHover { hover in
            isHovering = hover
        }
    }
}
