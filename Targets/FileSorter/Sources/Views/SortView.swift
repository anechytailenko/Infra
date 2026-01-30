import SwiftUI

struct SortView: View {
    @StateObject private var viewModel = SortViewModel()
    @State private var pathInput: String = "/Users/jdoe/Downloads"
    
    var body: some View {
        ZStack {
            AppStyle.screenBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - State 1: Input (Initial)
                if viewModel.rootFolderNode == nil && !viewModel.isLoadingTree {
                    inputSection
                }
                
                // MARK: - State 2: Loading Tree
                if viewModel.isLoadingTree {
                    fullScreenLoadingView
                }
                
                // MARK: - State 3: Graph Display
                if let root = viewModel.rootFolderNode {
                    VStack(spacing: 0) {
                        
                        // 1. Interactive Graph
                        GeometryReader { geo in
                            GraphView(
                                root: root,
                                startDepth: viewModel.baseDepth,
                                selectedFile: viewModel.selectedFile,
                                // FIX: onManualMove corresponds to the Sort Mode parameters
                                onManualMove: { fileID, newFolderName in
                                    withAnimation {
                                        viewModel.updateFileDestination(fileID: fileID, newFolderName: newFolderName)
                                    }
                                },
                                // ActiveFile/ParentName are nil by default (Prompt Mode params), so we skip them
                                onAccept: { print("Accept Pressed") },
                                onDecline: { print("Decline Pressed") }
                            )
                            .frame(width: geo.size.width, height: geo.size.height)
                        }
                        
                        Divider()
                        
                        // 2. File List
                        if viewModel.isAnalyzing {
                            sortingLoadingView
                                .frame(height: 300)
                                .background(AppStyle.cardBackground)
                        } else {
                            FileMoveListView(
                                files: viewModel.allFilesList,
                                headerTitle: root.name,
                                selectedFile: $viewModel.selectedFile,
                                onCancelMove: viewModel.cancelMove
                            )
                            .frame(height: 300)
                            .background(AppStyle.cardBackground)
                        }
                    }
                }
            }
        }
        .frame(minWidth: 1000, minHeight: 800)
    }
    
    // MARK: - Subviews
    // These MUST be inside the struct
    
    var inputSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 64))
                .foregroundColor(AppStyle.folderIconColor)
            
            Text("Select Folder to Analyze")
                .font(AppStyle.headlineFont)
            
            HStack {
                TextField("Path", text: $pathInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                
                Button("Start Analysis") {
                    viewModel.scanAndSortFolder(path: pathInput)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    var fullScreenLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(.blue)
            
            Text("Scanning file system...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var sortingLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.regular)
                .tint(.blue)
            
            Text("Sorting files & generating suggestions...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
// End of Struct
