import SwiftUI

// MARK: - HomeView
// Container that includes SearchView and GraphView.

struct HomeView: View {
    @StateObject private var viewModel = FolderStructureViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppStyle.screenBackground
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    SearchView(searchText: $searchText, onSort: {})
                    GraphView(root: viewModel.rootNode)
                }
            }
        }
    }
}
