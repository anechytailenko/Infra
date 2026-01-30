import SwiftUI

// MARK: - AppStyle
// Shared styling constants used by GraphView, SortDecisionView, and other app views.

struct AppStyle {

    // MARK: - Background / Surface

    static let screenBackground = Color(white: 0.90)
    static let cardBackground = Color.white
    static let cardCornerRadius: CGFloat = 16
    static let cardShadowColor = Color.black.opacity(0.05)
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowX: CGFloat = 0
    static let cardShadowY: CGFloat = 4

    // MARK: - Typography

    static let textPrimary = Color.black
    static let textSecondary = Color.gray
    static let headlineFont = Font.system(.headline, design: .default)
    static let bodyFontSize: CGFloat = 14
    static let bodyFontWeight: Font.Weight = .medium
    static let captionFont = Font.caption

    // MARK: - Tree / Diagram Nodes

    static let folderIconColor = Color.blue
    static let nodeFillOpacity: Double = 0.15
    static let nodeBorderOpacity: Double = 0.3
    static let nodeCornerRadius: CGFloat = 12
    static let nodePaddingHorizontal: CGFloat = 16
    static let nodePaddingVertical: CGFloat = 10
    static let nodeBorderLineWidth: CGFloat = 1
    static let nodeIconFont = Font.headline
    static let nodeTextFont = Font.system(size: 13, weight: .medium)
    static let nodeHStackSpacing: CGFloat = 8

    // MARK: - Edges / Connections

    static let edgeNormalColor = Color.blue.opacity(0.4)
    static let edgeNormalLineWidth: CGFloat = 2
}
