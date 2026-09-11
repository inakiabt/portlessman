import SwiftUI
import AppKit

struct LogsModalView: View {
    @ObservedObject var store: PortlessStore
    let onBack: () -> Void
    @State private var logContent: String = ""
    @State private var copiedFeedback: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Navigation Bar
            HStack {
                Button {
                    onBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(NavigationBackButtonStyle())
                .keyboardShortcut(.cancelAction)

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "doc.plaintext")
                        .font(.system(size: 12))
                    Text("Proxy Logs")
                        .font(.system(size: 13, weight: .bold))
                }

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(logContent, forType: .string)
                        copiedFeedback = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            copiedFeedback = false
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 9))
                            Text(copiedFeedback ? "Copied" : "Copy")
                                .font(.system(size: 10))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)

                    Button {
                        refreshLogs()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 4)

            Divider()

            ScrollView([.horizontal, .vertical]) {
                Text(logContent.isEmpty ? "No log output available" : logContent)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .textSelection(.enabled)
            }
            .background(Color.primary.opacity(0.03))
            .cornerRadius(6)
            .padding(.horizontal, 14)
            .frame(height: 280)
        }
        .padding(.bottom, 10)
        .onAppear {
            refreshLogs()
        }
    }

    private func refreshLogs() {
        self.logContent = store.getProxyLogs(maxLines: 200)
    }
}
