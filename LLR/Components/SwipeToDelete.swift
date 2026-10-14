import SwiftUI

/// Swipe left to delete, swipe right to edit, for cards that live in a ScrollView where the native
/// List swipe actions aren't available. The card follows the finger 1:1 and settles with a spring.
struct SwipeToDelete: ViewModifier {
    private enum Side { case closed, delete, edit }
    private enum DragAxis { case undecided, horizontal, vertical }

    let id: UUID
    @Binding var openID: UUID?
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var side: Side = .closed
    @State private var axis: DragAxis = .undecided
    @State private var width: CGFloat = 320
    @State private var pastThreshold = false
    @State private var fireCount = 0
    @State private var firing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let actionWidth: CGFloat = 88
    private let radius: CGFloat = 14
    private let fullSwipeFraction: CGFloat = 0.6

    func body(content: Content) -> some View {
        ZStack {
            actions
            content
                .allowsHitTesting(side == .closed)
                .overlay { closeCatcher }
                .offset(x: offset)
                .opacity(firing && reduceMotion ? 0 : 1)
        }
        .background(widthReader)
        .simultaneousGesture(drag)
        .onChange(of: openID) { _, new in
            if new != id && side != .closed { settle(to: .closed) }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: pastThreshold)
        .sensoryFeedback(.impact(weight: .medium), trigger: fireCount)
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: "Edit") { onEdit() }
        .accessibilityAction(named: "Delete") { fire() }
    }

    private var widthReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { width = proxy.size.width }
                .onChange(of: proxy.size.width) { _, new in width = new }
        }
    }

    // MARK: Revealed buttons

    @ViewBuilder private var actions: some View {
        if offset < 0 {
            strip(color: Theme.over, title: "Delete", icon: "trash", alignment: .trailing, action: fire)
                .frame(maxWidth: .infinity, alignment: .trailing)
        } else if offset > 0 {
            strip(color: Theme.accent, title: "Edit", icon: "pencil", alignment: .leading, action: edit)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Sized to the exposed gap only, so the card's see-through background never shows colour behind it.
    private func strip(color: Color, title: String, icon: String, alignment: Alignment,
                       action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: alignment) {
                color
                VStack(spacing: 4) {
                    Image(systemName: icon)
                    Text(title)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: actionWidth)
            }
        }
        .buttonStyle(.plain)
        .frame(width: abs(offset))
        .clipShape(RoundedRectangle(cornerRadius: radius))
        .accessibilityHidden(true)
    }

    @ViewBuilder private var closeCatcher: some View {
        if side != .closed {
            Color.clear.contentShape(Rectangle()).onTapGesture { settle(to: .closed) }
        }
    }

    // MARK: Gesture

    private var baseOffset: CGFloat {
        switch side {
        case .closed: return 0
        case .delete: return -actionWidth
        case .edit: return actionWidth
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                if axis == .undecided {
                    // Vertical scrolling wins unless the drag is clearly sideways.
                    let dx: CGFloat = abs(value.translation.width)
                    let dy: CGFloat = abs(value.translation.height)
                    axis = dx > dy * 1.6 ? .horizontal : .vertical
                    if axis == .horizontal { openID = id }
                }
                guard axis == .horizontal, !firing else { return }
                offset = rubberBand(baseOffset + value.translation.width)
                let crossed: Bool = -offset > width * fullSwipeFraction
                if crossed != pastThreshold { pastThreshold = crossed }
            }
            .onEnded { value in
                let wasHorizontal: Bool = axis == .horizontal
                axis = .undecided
                guard wasHorizontal, !firing else { return }
                let projected: CGFloat = baseOffset + value.predictedEndTranslation.width
                if -offset > width * fullSwipeFraction || -projected > width * 0.9 {
                    fire()
                } else if projected < -actionWidth / 2 {
                    settle(to: .delete)
                } else if projected > actionWidth / 2 {
                    settle(to: .edit)
                } else {
                    settle(to: .closed)
                }
            }
    }

    /// A full swipe to the left is allowed; everything past the other limits resists.
    private func rubberBand(_ x: CGFloat) -> CGFloat {
        if x > actionWidth { return actionWidth + (x - actionWidth) * 0.25 }
        if x < -width { return -width - (-width - x) * 0.25 }
        return x
    }

    // MARK: Actions

    private var settleAnimation: Animation {
        reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.35, dampingFraction: 0.82)
    }

    private func settle(to target: Side) {
        side = target
        pastThreshold = false
        if target == .closed {
            if openID == id { openID = nil }
        } else {
            openID = id
        }
        withAnimation(settleAnimation) { offset = baseOffset }
    }

    private func edit() {
        settle(to: .closed)
        onEdit()
    }

    private func fire() {
        guard !firing else { return }
        firing = true
        fireCount += 1
        withAnimation(.easeOut(duration: 0.2)) {
            if !reduceMotion { offset = -width }
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            if openID == id { openID = nil }
            withAnimation(.snappy) { onDelete() }
        }
    }
}

extension View {
    func swipeToDelete(id: UUID, openID: Binding<UUID?>, onEdit: @escaping () -> Void,
                       onDelete: @escaping () -> Void) -> some View {
        modifier(SwipeToDelete(id: id, openID: openID, onEdit: onEdit, onDelete: onDelete))
    }

    /// A vertical scroll closes whichever row is open; sideways drags are the rows' own business.
    func closesSwipeOnScroll(_ openID: Binding<UUID?>) -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: 10).onChanged { value in
                let vertical: Bool = abs(value.translation.height) > abs(value.translation.width)
                if vertical && openID.wrappedValue != nil { openID.wrappedValue = nil }
            }
        )
    }
}
