import Foundation
import SwiftUI

// MARK: - PromptViewModel
// View model for PromptView. Builds a folder tree from matched file paths
// starting at "home" and renders the full nested structure (e.g. home -> animals, home -> lion).

class PromptViewModel: ObservableObject {
    
    let userPrompt: String
    private let matchedPaths: [String]
    
    @Published var rootNode: FolderNode?
    @Published var activeFile: PromptFile?
    @Published var folderName: String = "Matched Results"
    @Published var files: [PromptFile] = []
    
    var selectedCount: Int { files.filter { $0.isSelected }.count }
    var isAllSelected: Bool { !files.isEmpty && files.allSatisfy { $0.isSelected } }
    
    /// Root segment for the graph; only nodes from this path onward are shown.
    private static let graphRootSegment = "home"
    
    init(promptText: String, matchedPaths: [String]) {
        self.userPrompt = promptText
        self.matchedPaths = matchedPaths
        loadData()
    }
    
    func setActiveFile(_ file: PromptFile) { self.activeFile = file }
    
    func getParentFolder(for file: PromptFile) -> String? {
        guard let components = Self.componentsFromHome(file.fullPath), components.count > 1 else { return nil }
        return components[components.count - 2]
    }
    
    func loadData() {
        files = matchedPaths.map { path in
            PromptFile(path: path, size: "Unknown", isSelected: false, isMatched: true)
        }
        
        let folderTree = buildFolderTree(from: matchedPaths)
        let matchedFolderNames = Set(matchedPaths.compactMap { path -> String? in
            guard let comps = Self.componentsFromHome(path), comps.count > 1 else { return nil }
            return comps[comps.count - 2]
        })
        var mutableRoot = folderTree
        updateMatches(in: &mutableRoot, matchedNames: matchedFolderNames)
        self.rootNode = mutableRoot
    }
    
    // MARK: - Path helpers
    
    private static func pathComponents(_ path: String) -> [String] {
        path.replacingOccurrences(of: "\\", with: "/").components(separatedBy: "/")
    }
    
    /// Path segments from "home" (inclusive) up to but not including the filename.
    /// Returns nil if "home" is not found in the path.
    private static func componentsFromHome(_ path: String) -> [String]? {
        let components = pathComponents(path)
        guard let homeIndex = components.firstIndex(of: graphRootSegment) else { return nil }
        let fromHome = Array(components[homeIndex...])
        guard fromHome.count >= 1 else { return nil }
        let withoutFilename = fromHome.count > 1 ? Array(fromHome.dropLast()) : fromHome
        return withoutFilename.filter { !$0.isEmpty }
    }
    
    /// Builds a nested folder tree from matched paths, starting at "home".
    /// Example: paths containing home/animals/... and home/lion/... yield home -> [animals, lion].
    private func buildFolderTree(from paths: [String]) -> FolderNode {
        var segmentsFromHome: [[String]] = []
        for path in paths {
            guard let comps = Self.componentsFromHome(path), !comps.isEmpty else { continue }
            segmentsFromHome.append(comps)
        }
        
        if segmentsFromHome.isEmpty {
            return FolderNode(name: Self.graphRootSegment, children: [])
        }
        
        return buildTree(segments: segmentsFromHome, depth: 0)
    }
    
    private func buildTree(segments: [[String]], depth: Int) -> FolderNode {
        let name = segments[0][depth]
        let childNames = Set(segments.compactMap { seg in
            seg.count > depth + 1 ? seg[depth + 1] : nil
        })
        let children: [FolderNode] = childNames.sorted().map { childName in
            let subSegments = segments
                .filter { $0.count > depth + 2 && $0[depth + 1] == childName }
                .map { Array($0[(depth + 2)...]) }
                .filter { !$0.isEmpty }
            if subSegments.isEmpty {
                return FolderNode(name: childName, children: [])
            }
            return buildTree(segments: subSegments, depth: 0)
        }
        return FolderNode(name: name, children: children)
    }
    
    private func updateMatches(in node: inout FolderNode, matchedNames: Set<String>) {
        if matchedNames.contains(node.name) { node.isMatched = true }
        for i in 0..<node.children.count {
            updateMatches(in: &node.children[i], matchedNames: matchedNames)
        }
    }
    
    func toggleSelection(for id: UUID) {
        if let index = files.firstIndex(where: { $0.id == id }) { files[index].isSelected.toggle() }
    }
    
    func toggleSelectAll() {
        if isAllSelected { deselectAll() } else { selectAll() }
    }
    
    func selectAll() { for i in 0..<files.count { files[i].isSelected = true } }
    func deselectAll() { for i in 0..<files.count { files[i].isSelected = false } }
    
    func deleteSelected() {
        withAnimation { files.removeAll { $0.isSelected } }
    }
}
