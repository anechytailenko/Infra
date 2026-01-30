import Foundation
import SwiftUI

// MARK: - File Row Model
struct FileRowDisplay: Identifiable {
    let id: UUID
    let fileName: String
    let destination: String?
    
    init(id: UUID = UUID(), fileName: String, destination: String?) {
        self.id = id
        self.fileName = fileName
        self.destination = destination
    }
}

@MainActor
class SortViewModel: ObservableObject {
    
    // MARK: - State
    @Published var rootFolderNode: FolderNode?
    @Published var proposedMoves: [FileMoveAction] = []
    @Published var allFilesList: [FileRowDisplay] = []
    @Published var baseDepth: Int = 0
    @Published var isLoadingTree: Bool = false
    @Published var isAnalyzing: Bool = false
    @Published var errorMessage: String?
    @Published var selectedFile: FileRowDisplay? = nil
    
    // MARK: - Services
    private let treeService = FileTreeService()
    private let sortingService = SortingService()
    
    // MARK: - Logic
    func selectFile(_ file: FileRowDisplay) {
        if selectedFile?.id == file.id {
            selectedFile = nil
        } else {
            selectedFile = file
        }
    }
    
    func cancelMove(for fileID: UUID) {
        guard let index = allFilesList.firstIndex(where: { $0.id == fileID }) else { return }
        let oldItem = allFilesList[index]
        let newItem = FileRowDisplay(id: oldItem.id, fileName: oldItem.fileName, destination: nil)
        allFilesList[index] = newItem
        if selectedFile?.id == fileID { selectedFile = newItem }
    }
    
    // Updates model when file is dropped
    func updateFileDestination(fileID: UUID, newFolderName: String) {
        guard let index = allFilesList.firstIndex(where: { $0.id == fileID }) else { return }
        let oldItem = allFilesList[index]
        let newItem = FileRowDisplay(id: oldItem.id, fileName: oldItem.fileName, destination: newFolderName)
        allFilesList[index] = newItem
        if selectedFile?.id == fileID { selectedFile = newItem }
    }
    
    func scanAndSortFolder(path: String) {
        self.errorMessage = nil
        self.rootFolderNode = nil
        self.proposedMoves = []
        self.allFilesList = []
        
        let slashCount = path.filter { $0 == "/" }.count
        self.baseDepth = max(0, slashCount - 1)
        
        Task {
            do {
                self.isLoadingTree = true
                let initialTree = try await treeService.fetchFileTree(path: path)
                self.rootFolderNode = self.mapToFolderNode(initialTree, newFolders: [])
                self.isLoadingTree = false
                
                self.isAnalyzing = true
                let result = try await sortingService.fetchSuggestions(for: initialTree)
                let newFolderNames = ["Images", "Documents"]
                self.rootFolderNode = self.mapToFolderNode(result.updatedTree, newFolders: newFolderNames)
                self.proposedMoves = result.moves
                self.allFilesList = self.generateFullFileList(sourceTree: result.updatedTree, moves: result.moves)
                self.isAnalyzing = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoadingTree = false
                self.isAnalyzing = false
            }
        }
    }
    
    private func generateFullFileList(sourceTree: FileSystemNode, moves: [FileMoveAction]) -> [FileRowDisplay] {
        var displayList: [FileRowDisplay] = []
        if case .folder(let rootItem) = sourceTree {
            let allFiles = rootItem.children.compactMap { child -> FileItem? in
                if case .file(let fileItem) = child { return fileItem }
                return nil
            }
            for file in allFiles {
                if let moveAction = moves.first(where: { $0.fileName == file.name }) {
                    displayList.append(FileRowDisplay(fileName: file.name, destination: moveAction.destination))
                } else {
                    displayList.append(FileRowDisplay(fileName: file.name, destination: nil))
                }
            }
        }
        return displayList
    }
    
    private func mapToFolderNode(_ node: FileSystemNode, newFolders: [String]) -> FolderNode? {
        switch node {
        case .folder(let item):
            let isNew = newFolders.contains(item.name)
            let folderChildren = item.children.compactMap { mapToFolderNode($0, newFolders: newFolders) }
            return FolderNode(name: item.name, isNew: isNew, children: folderChildren)
        case .file:
            return nil
        }
    }
}
