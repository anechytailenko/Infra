import SwiftUI

// MARK: - SortDecisionStyle
// Reusable styling constants for SortDecisionView and subviews.

struct SortDecisionStyle {

    // MARK: - Layout

    static let mainPadding: CGFloat = 24
    static let stackSpacing: CGFloat = 16
    static let minWidth: CGFloat = 900
    static let minHeight: CGFloat = 750
    static let proposedListHeight: CGFloat = 280
    static let cardCornerRadius: CGFloat = 16
    static let diagramInnerPadding: CGFloat = 100
    static let zoomMin: CGFloat = 0.5
    static let zoomMax: CGFloat = 3.0

    // MARK: - Background / Surface

    static let mainBackgroundGray = Color(white: 0.90)
    static let cardBackground = Color.white
    static let listZebraGray = Color(white: 0.97)
    static let listRowEven = Color.white

    // MARK: - Typography

    static let listHeaderFont = Font.system(.headline, design: .default)
    static let listHeaderIconFont = Font.title3
    static let rowFileNameFont = Font.system(size: 14, weight: .medium)
    static let rowMovedToFont = Font.system(size: 14)
    static let rowIconFont = Font.title3
    static let buttonFont = Font.system(size: 14, weight: .semibold)
    static let nodeIconFont = Font.headline
    static let nodeTextFont = Font.system(size: 13, weight: .medium)

    // MARK: - Colors – Text / UI

    static let textPrimary = Color.black
    static let textSecondary = Color.gray
    static let folderIconColor = Color.blue
    static let listRowIconColor = Color.gray
    static let declineButtonRed = Color.red
    static let declineButtonGray = Color.gray.opacity(0.5)
    static let emptyListPlaceholderColor = Color.gray
    static let buttonForeground = Color.white
    static let acceptButtonColor = Color.blue
    static let declineButtonColor = Color.gray

    // MARK: - Colors – Diagram Edges

    static let edgeNormalColor = Color.blue.opacity(0.4)
    static let edgeOriginalFileColor = Color.red.opacity(0.6)
    static let edgeProposedFileColor = Color.green

    // MARK: - Colors – Diagram Nodes

    static let nodeFillOpacity: Double = 0.15
    static let nodeBorderOpacity: Double = 0.3
    static let nodeGhostBorderOpacity: Double = 0.5
    static let nodeShadowOpacity: Double = 0.15
    static let nodeGhostShadowOpacity: Double = 0.0

    // MARK: - Edges / Connections

    static let edgeNormalLineWidth: CGFloat = 2
    static let edgeOriginalFileLineWidth: CGFloat = 1.5
    static let edgeProposedFileLineWidth: CGFloat = 2
    static let edgeOriginalFileDash: [CGFloat] = [5, 5]
    static let nodeGhostDash: [CGFloat] = [4, 4]
    static let edgeCurveControlFactor: CGFloat = 0.5

    // MARK: - Node (DiagramNodeView)

    static let nodeHStackSpacing: CGFloat = 8
    static let nodePaddingHorizontal: CGFloat = 16
    static let nodePaddingVertical: CGFloat = 10
    static let nodeCornerRadius: CGFloat = 12
    static let nodeBorderLineWidth: CGFloat = 1
    static let nodeShadowRadius: CGFloat = 6
    static let nodeShadowY: CGFloat = 3

    // MARK: - Shadows

    static let cardShadowColor = Color.black.opacity(0.05)
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowX: CGFloat = 0
    static let cardShadowY: CGFloat = 4
    static let buttonShadowOpacity: Double = 0.3
    static let buttonShadowRadius: CGFloat = 4
    static let buttonShadowY: CGFloat = 2

    // MARK: - List / Rows

    static let listHeaderHStackSpacing: CGFloat = 8
    static let listRowHStackSpacing: CGFloat = 12
    static let listRowPaddingHorizontal: CGFloat = 16
    static let listRowPaddingVertical: CGFloat = 12
    static let listDividerOverlayOpacity: Double = 0.1
    static let listSelectedRowTintOpacity: Double = 0.1

    // MARK: - Buttons (NiceButtonStyle)

    static let buttonPaddingHorizontal: CGFloat = 24
    static let buttonPaddingVertical: CGFloat = 10
    static let buttonPressScale: CGFloat = 0.96
    static let buttonPressAnimationDuration: Double = 0.1

    // MARK: - Animation

    static let rowSelectSpringResponse: Double = 0.4
    static let rowSelectSpringDamping: Double = 0.7
    static let rowDeclineHoverDuration: Double = 0.2
    static let rowDeclineHoverScale: CGFloat = 1.1

    // MARK: - Diagram Layout

    static let diagramRootXFactor: CGFloat = 0.2
    static let diagramRootYFactor: CGFloat = 0.5
    static let diagramFolderColumnXFactor: CGFloat = 0.6
    static let diagramFolderSpacingY: CGFloat = 100
    static let diagramFileOriginalOffsetX: CGFloat = 40
    static let diagramFileOriginalOffsetY: CGFloat = 70
    static let diagramFileProposedOffsetX: CGFloat = 160
    static let diagramFileProposedOffsetY: CGFloat = 0
    /// Minimum size used for layout so the tree stays visible when the window is small.
    static let diagramMinLayoutWidth: CGFloat = 420
    static let diagramMinLayoutHeight: CGFloat = 320
    static let diagramHorizontalMargin: CGFloat = 48
    static let diagramVerticalMargin: CGFloat = 40
}
