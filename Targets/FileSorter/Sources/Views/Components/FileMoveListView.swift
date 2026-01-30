import SwiftUI

struct FileMoveListView: View {
    let files: [FileRowDisplay]
    let headerTitle: String
    
    // Binding to handle selection in parent view
    @Binding var selectedFile: FileRowDisplay?
    
    // NEW: Action when cross is clicked
    var onCancelMove: ((UUID) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - Header
            HStack(spacing: 12) {
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundColor(AppStyle.folderIconColor)
                
                Text(headerTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppStyle.textPrimary)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            .background(Color.white)
            
            Divider()
            
            // MARK: - List Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(files.enumerated()), id: \.element.id) { index, fileRow in
                        MoveRow(
                            fileRow: fileRow,
                            onCancel: {
                                // Pass action up to parent
                                onCancelMove?(fileRow.id)
                            }
                        )
                        .background(
                            self.backgroundColor(for: fileRow, index: index)
                        )
                        .onTapGesture {
                            withAnimation {
                                if selectedFile?.id == fileRow.id {
                                    selectedFile = nil
                                } else {
                                    selectedFile = fileRow
                                }
                            }
                        }
                        // Drag source: allows dragging file to folder nodes
                        .draggable(fileRow.id.uuidString) {
                            // Drag preview
                            Label(fileRow.fileName, systemImage: "doc.fill")
                                .padding(8)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(radius: 4)
                        }

                    }
                }
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private func backgroundColor(for row: FileRowDisplay, index: Int) -> Color {
        if selectedFile?.id == row.id {
            return Color.blue.opacity(0.1)
        }
        return index % 2 == 0 ? Color.white : Color.gray.opacity(0.08)
    }
}

// MARK: - MoveRow Component
struct MoveRow: View {
    let fileRow: FileRowDisplay
    var onCancel: () -> Void
    
    // NEW: State for hover effect
    @State private var isHovering: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            // Icon
            Image(systemName: "doc")
                .foregroundColor(SortDecisionStyle.listRowIconColor)
                .font(SortDecisionStyle.rowIconFont)
                .frame(width: 30)
            
            // File Name
            Text(fileRow.fileName)
                .font(SortDecisionStyle.rowFileNameFont)
                .foregroundColor(AppStyle.textPrimary)
                .padding(.leading, 8)
            
            Spacer()
            
            // "Moved to" Section (Only if destination exists)
            if let destination = fileRow.destination {
                HStack(spacing: 4) {
                    Text("moved to:")
                        .font(SortDecisionStyle.rowMovedToFont)
                        .foregroundColor(AppStyle.textSecondary)
                    
                    Text(destination)
                        .font(SortDecisionStyle.rowFileNameFont)
                        .foregroundColor(AppStyle.textPrimary)
                }
                .padding(.trailing, 16)
                
                // Cancel/Decline Button with Hover Logic
                Button(action: {
                    withAnimation {
                        onCancel()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: isHovering ? 18 : 16)) // Grow on hover
                        .foregroundColor(isHovering ? .red : SortDecisionStyle.declineButtonGray.opacity(0.6)) // Red on hover
                        .scaleEffect(isHovering ? 1.1 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isHovering = hovering
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}
