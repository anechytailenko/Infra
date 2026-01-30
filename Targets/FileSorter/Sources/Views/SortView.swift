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
                    // #region agent log
                    let _ = {
                        let logData: [String: Any] = ["sessionId": "debug-session", "runId": "run1", "hypothesisId": "C", "location": "SortView.swift:graphDisplay", "message": "Root node available", "data": ["rootName": root.name, "childrenCount": root.children.count], "timestamp": Date().timeIntervalSince1970 * 1000]
                        if let jsonData = try? JSONSerialization.data(withJSONObject: logData), let jsonString = String(data: jsonData, encoding: .utf8) {
                            let logPath = "/Users/hermanhavva/Documents/Personal/projects/FileSorterApp/.cursor/debug.log"
                            if let handle = FileHandle(forWritingAtPath: logPath) {
                                handle.seekToEndOfFile()
                                handle.write((jsonString + "\n").data(using: .utf8)!)
                                handle.closeFile()
                            } else {
                                FileManager.default.createFile(atPath: logPath, contents: (jsonString + "\n").data(using: .utf8))
                            }
                        }
                    }()
                    // #endregion
                    VStack(spacing: 0) {
                        
                        // 1. Interactive Graph
                        GeometryReader { geo in
                            // #region agent log
                            let _ = {
                                let logData: [String: Any] = ["sessionId": "debug-session", "runId": "run1", "hypothesisId": "D", "location": "SortView.swift:GeometryReader", "message": "Graph GeometryReader size", "data": ["width": geo.size.width, "height": geo.size.height], "timestamp": Date().timeIntervalSince1970 * 1000]
                                if let jsonData = try? JSONSerialization.data(withJSONObject: logData), let jsonString = String(data: jsonData, encoding: .utf8) {
                                    let logPath = "/Users/hermanhavva/Documents/Personal/projects/FileSorterApp/.cursor/debug.log"
                                    if let handle = FileHandle(forWritingAtPath: logPath) {
                                        handle.seekToEndOfFile()
                                        handle.write((jsonString + "\n").data(using: .utf8)!)
                                        handle.closeFile()
                                    } else {
                                        FileManager.default.createFile(atPath: logPath, contents: (jsonString + "\n").data(using: .utf8))
                                    }
                                }
                            }()
                            // #endregion
                            GraphView(
                                root: root,
                                startDepth: viewModel.baseDepth,
                                selectedFile: viewModel.selectedFile,
                                onAccept: { print("Accept Pressed") },
                                onDecline: { print("Decline Pressed") },
                                
                                // Wiring up Drag & Drop within graph
                                onManualMove: { fileID, newFolderName in
                                    withAnimation {
                                        viewModel.updateFileDestination(fileID: fileID, newFolderName: newFolderName)
                                    }
                                },
                                
                                // Wiring up Drag & Drop from file list to graph
                                onFileDrop: { fileUUIDString, folderName in
                                    withAnimation {
                                        viewModel.updateFileDestination(fileUUIDString: fileUUIDString, newFolderName: folderName)
                                    }
                                }
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
                                onCancelMove: viewModel.cancelMove // Wiring up the Cancel (X) button
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
