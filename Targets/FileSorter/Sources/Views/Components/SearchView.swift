import SwiftUI

// MARK: - SearchView
// Header with search bar and enter (submit) button; used by HomeView.

struct SearchView: View {
    @Binding var searchText: String
    /// Optional example query shown when the field is empty; styled lightly so the user understands it is an example. Disappears when the user types.
    var exampleQuery: String? = nil
    var onSort: (() -> Void)? = nil

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppStyle.textSecondary)
                Group {
                    if let exampleQuery = exampleQuery {
                        TextField("Smart search", text: $searchText, prompt: Text(exampleQuery).foregroundStyle(AppStyle.searchExampleColor))
                    } else {
                        TextField("Smart search", text: $searchText)
                    }
                }
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                .foregroundStyle(AppStyle.textPrimary)
                .onSubmit { onSort?() }
            }
            .padding(GraphViewStyle.searchBarPadding)
            .background(AppStyle.cardBackground)
            .cornerRadius(GraphViewStyle.searchBarCornerRadius)
            .frame(width: GraphViewStyle.searchBarWidth)
            .overlay(alignment: .leading) {
                if let eq = exampleQuery, searchText.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AppStyle.textSecondary)
                        Text(eq)
                            .font(.system(size: AppStyle.bodyFontSize, weight: AppStyle.bodyFontWeight))
                            .foregroundStyle(AppStyle.searchExampleColor)
                    }
                    .padding(GraphViewStyle.searchBarPadding)
                    .allowsHitTesting(false)
                }
            }

            Button(action: { onSort?() }) {
                Image(systemName: "arrow.turn.down.left")
                    .font(.system(size: GraphViewStyle.sortButtonIconFontSize, weight: .medium))
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
