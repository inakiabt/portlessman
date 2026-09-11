import SwiftUI
import AppKit

struct LogsModalView: View {
    @ObservedObject var store: PortlessStore
    @Environment(\.dismiss) private var dismiss
    @State private var logContent: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Proxy Logs", systemImage: "doc.plaintext")
                    .font(.headline)

                Spacer()

                Button {
                    refreshLogs()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)

                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(logContent, forType: .string)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Divider()

            ScrollView([.horizontal, .vertical]) {
                Text(logContent.isEmpty ? "No log output available" : logContent)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .textSelection(.enabled)
            }
            .background(Color.primary.opacity(0.04))
            .cornerRadius(6)
            .frame(height: 280)
        }
        .padding(16)
        .frame(width: 480)
        .onAppear {
            refreshLogs()
        }
    }

    private func refreshLogs() {
        self.logContent = store.getProxyLogs(maxLines: 200)
    }
}
