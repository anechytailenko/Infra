import Foundation

/// Tree node for the folder graph on the home screen. Used by HomeViewModel and GraphView.
struct FolderNode: Identifiable {
    let id = UUID()
    let name: String
    var children: [FolderNode] = []
}
