import SwiftUI

// MARK: - FolderDetailStyle
// Style constants used only by FolderDetailView and its subviews (file list, history list).

struct FolderDetailStyle {

    // MARK: - Background / Layout

    static let detailBackground = Color(white: 0.92)
    static let sectionSpacing: CGFloat = 20
    static let contentPaddingHorizontal: CGFloat = 20
    static let contentPaddingTop: CGFloat = 20
    static let contentPaddingBottom: CGFloat = 40

    // MARK: - Graph card

    static let graphCardMinHeight: CGFloat = 180

    // MARK: - File list

    /// Fixed height for the file list card when showing items (fits ~3 rows); list body scrolls if more.
    static let fileListHeight: CGFloat = 145
    /// Reduced height when the file list is empty (header + placeholder only).
    static let fileListHeightEmpty: CGFloat = 85
    static let listHeaderHStackSpacing: CGFloat = 8
    static let listRowHStackSpacing: CGFloat = 12
    static let listRowPaddingHorizontal: CGFloat = 16
    static let listRowPaddingVertical: CGFloat = 5
    static let listRowIconSize: CGFloat = 16
    static let listDividerLeadingPadding: CGFloat = 50
    static let listDividerOpacity: Double = 0.1
    static let listCornerRadius: CGFloat = 12

    // MARK: - History

    static let historySuccessColor = Color.green
    static let historySuccessBorderOpacity: Double = 0.3
    static let historySuccessFillOpacity: Double = 0.1
    static let historyIconSize: CGFloat = 24

    // MARK: - Filter / Sort bar

    static let filterSortBarSpacing: CGFloat = 8
    static let filterSortBarPaddingVertical: CGFloat = 12
    /// Small icon-only button size for filter and sort.
    static let filterSortButtonSize: CGFloat = 28
    /// Visible background for menu buttons (macOS borderless Menu often doesn't draw the label).
    static let menuButtonBackground = Color.gray.opacity(0.35)
    static let menuButtonCornerRadius: CGFloat = 6
    /// Icon color for menu buttons (gray so they show on white card).
    static let menuButtonIconColor = Color(white: 0.35)
}
