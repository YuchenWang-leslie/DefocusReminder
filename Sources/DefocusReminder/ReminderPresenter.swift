import AppKit
import SwiftUI

private final class FloatingReminderPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class ReminderPresenter {
    private var panel: FloatingReminderPanel?

    func show(model: AppModel) {
        if let panel {
            position(panel)
            panel.orderFrontRegardless()
            return
        }

        let view = FloatingReminderView(model: model)
            .frame(width: 280)
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.18), radius: 16, y: 8)

        let hosting = NSHostingView(rootView: view)
        hosting.frame = NSRect(x: 0, y: 0, width: 280, height: 230)

        let panel = FloatingReminderPanel(
            contentRect: hosting.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.contentView = hosting
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        position(panel)
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    private func position(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        guard let screen else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let margin: CGFloat = 18
        panel.setFrameOrigin(NSPoint(
            x: visible.maxX - size.width - margin,
            y: visible.maxY - size.height - margin
        ))
    }

    static var userIsActive: Bool {
        let mouse = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved)
        let keyboard = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown)
        return min(mouse, keyboard) < 3
    }
}

struct FloatingReminderView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(color)

            VStack(spacing: 5) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if model.engine.phase == .breaking || model.engine.phase == .breakPrompt {
                recommendation
            }

            HStack(spacing: 10) {
                ForEach(actions, id: \.title) { action in
                    Button(action.title) {
                        action.perform()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(action.tint)
                }
            }
        }
    }

    private var recommendation: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: model.currentRecommendation.icon)
                .foregroundStyle(.green)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 3) {
                Text(model.currentRecommendation.title(language: model.language))
                    .font(.system(size: 12, weight: .semibold))
                Text(model.currentRecommendation.detail(language: model.language))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private var icon: String {
        switch model.engine.phase {
        case .breakPrompt:
            return model.engine.promptKind == .finishBreak ? "checkmark.circle.fill" : "bell.badge.fill"
        case .breaking:
            return "cup.and.saucer.fill"
        case .paused:
            return "pause.circle.fill"
        default:
            return "timer"
        }
    }

    private var color: Color {
        switch model.engine.phase {
        case .breakPrompt:
            return model.engine.promptKind == .finishBreak ? .green : .orange
        case .breaking:
            return .orange
        case .paused:
            return .secondary
        default:
            return .blue
        }
    }

    private var title: String {
        if model.engine.phase == .breaking {
            return "\(L.phase(.breaking, model.language)) \(model.formattedRemaining)"
        }
        if model.engine.promptKind == .finishBreak {
            return L.s("休息结束了", "Break is done", model.language)
        }
        return L.s("该休息了", "Time to rest", model.language)
    }

    private var subtitle: String {
        if model.engine.phase == .breaking, model.config.activityDetectionEnabled {
            return L.s("检测到操作会暂停休息倒计时", "Activity pauses the break timer", model.language)
        }
        if model.engine.promptKind == .finishBreak {
            return L.s("准备好回到工作了吗？", "Ready to return to work?", model.language)
        }
        return L.s("点击开始休息，离开屏幕一会儿。", "Start the break and step away from the screen.", model.language)
    }

    private var actions: [FloatingAction] {
        if model.engine.phase == .breaking {
            return [
                FloatingAction(title: L.s("跳过", "Skip", model.language), tint: .gray) { model.skipBreak() },
            ]
        }
        if model.engine.promptKind == .finishBreak {
            return [
                FloatingAction(title: L.s("我回来了", "I'm back", model.language), tint: .green) { model.finishBreak() },
            ]
        }
        return [
            FloatingAction(title: L.s("开始休息", "Start break", model.language), tint: .orange) { model.startBreak() },
            FloatingAction(title: L.s("跳过", "Skip", model.language), tint: .gray) { model.skipBreak() },
        ]
    }
}

private struct FloatingAction {
    let title: String
    let tint: Color
    let perform: () -> Void
}
