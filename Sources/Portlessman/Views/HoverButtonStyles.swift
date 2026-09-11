import SwiftUI

// MARK: - Reusable Modern macOS Hover & Press Button Styles

/// Standard action pill button (e.g. Open, URL, Prune, Add, Copy)
struct ActionPillButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        configuration.isPressed
                            ? Color.primary.opacity(0.14)
                            : (isHovered ? Color.primary.opacity(0.10) : Color.primary.opacity(0.05))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isHovered ? Color.primary.opacity(0.12) : Color.primary.opacity(0.04), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
            .onHover { hovering in isHovered = hovering }
    }
}

/// Primary prominent pill button (e.g. blue Open button in Route Details)
struct PrimaryPillButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        configuration.isPressed
                            ? Color.blue.opacity(0.75)
                            : (isHovered ? Color.blue.opacity(0.88) : Color.blue)
                    )
            )
            .foregroundStyle(.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
            .onHover { hovering in isHovered = hovering }
    }
}

/// Destructive pill button (e.g. red Kill button in Route Details)
struct DestructivePillButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        let bgColor = configuration.isPressed
            ? Color.red.opacity(0.24)
            : (isHovered ? Color.red.opacity(0.18) : Color.red.opacity(0.10))
        let strokeColor = isHovered ? Color.red.opacity(0.30) : Color.clear

        return configuration.label
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(bgColor)
            )
            .foregroundStyle(Color.red)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
            .onHover { hovering in isHovered = hovering }
    }
}

/// Navigation Back button (< Back in modal headers)
struct NavigationBackButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        let bgColor = configuration.isPressed
            ? Color.primary.opacity(0.12)
            : (isHovered ? Color.primary.opacity(0.07) : Color.clear)

        return configuration.label
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(bgColor)
            )
            .foregroundStyle(isHovered ? .primary : .secondary)
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .onHover { hovering in isHovered = hovering }
    }
}

/// Navigation row button (e.g. Health Check Doctor, View Proxy Logs)
struct MenuRowButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        let bgColor = configuration.isPressed
            ? Color.primary.opacity(0.10)
            : (isHovered ? Color.primary.opacity(0.06) : Color.clear)

        return configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(bgColor)
            )
            .contentShape(Rectangle())
            .padding(.horizontal, 4)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .onHover { hovering in isHovered = hovering }
    }
}

/// Footer subtle link button (e.g. Preferences..., Quit)
struct FooterLinkButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        let bgColor = configuration.isPressed
            ? Color.primary.opacity(0.10)
            : (isHovered ? Color.primary.opacity(0.06) : Color.clear)

        return configuration.label
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(bgColor)
            )
            .foregroundStyle(isHovered ? .primary : .secondary)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .onHover { hovering in isHovered = hovering }
    }
}

/// Header round icon button (e.g. gear icon in main header)
struct HeaderIconButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        let bgColor = configuration.isPressed
            ? Color.primary.opacity(0.14)
            : (isHovered ? Color.primary.opacity(0.08) : Color.clear)

        return configuration.label
            .padding(5)
            .background(
                Circle()
                    .fill(bgColor)
            )
            .foregroundStyle(isHovered ? .primary : .secondary)
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .onHover { hovering in isHovered = hovering }
    }
}
