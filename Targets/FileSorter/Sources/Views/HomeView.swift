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
                    titleBarPane
                    SearchView(searchText: $searchText, onSort: {})
                    GraphView(root: viewModel.rootNode)
                }
            }
        }
    }

    private var titleBarPane: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: AppStyle.titleBarHeight)
                .frame(maxWidth: .infinity)
                .background(AppStyle.titleBarBackground)
            Rectangle()
                .fill(AppStyle.titleBarSeparatorColor)
                .frame(height: AppStyle.titleBarSeparatorHeight)
                .shadow(
                    color: AppStyle.titleBarSeparatorShadowColor,
                    radius: AppStyle.titleBarSeparatorShadowRadius,
                    x: 0,
                    y: AppStyle.titleBarSeparatorShadowY
                )
        }
    }
}
