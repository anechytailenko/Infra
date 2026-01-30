import SwiftUI

// MARK: - SearchView
// Header with search bar and Sort button; used by HomeView.

struct SearchView: View {
    @Binding var searchText: String
    var onSort: (() -> Void)? = nil

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppStyle.textSecondary)
                TextField("Smart search", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(GraphViewStyle.searchBarPadding)
            .background(AppStyle.cardBackground)
            .cornerRadius(GraphViewStyle.searchBarCornerRadius)
            .frame(width: GraphViewStyle.searchBarWidth)

            Button(action: { onSort?() }) {
                Text("Sort")
                    .fontWeight(.medium)
                    .foregroundStyle(AppStyle.textPrimary.opacity(0.8))
                    .padding(.horizontal, GraphViewStyle.sortButtonPaddingHorizontal)
                    .padding(.vertical, GraphViewStyle.sortButtonPaddingVertical)
                    .background(AppStyle.cardBackground)
                    .cornerRadius(GraphViewStyle.sortButtonCornerRadius)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, GraphViewStyle.headerTopPadding)
        .padding(.bottom, GraphViewStyle.headerBottomPadding)
    }
}
