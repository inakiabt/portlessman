import SwiftUI

struct DoctorModalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var report: DoctorReport? = nil
    @State private var isLoading: Bool = true
    @State private var errorText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Portless Doctor", systemImage: "stethoscope")
                    .font(.headline)

                Spacer()

                Button {
                    loadReport()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .disabled(isLoading)

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            Divider()

            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Running diagnostics...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else if let error = errorText {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundStyle(Color.red)
                    Text("Failed to run doctor")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else if let report = report {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        // Environment Info
                        VStack(alignment: .leading, spacing: 3) {
                            if let v = report.version {
                                Text("Portless v\(v)").font(.caption.bold())
                            }
                            if let node = report.nodeVersion {
                                Text("Node.js: \(node)").font(.caption).foregroundStyle(.secondary)
                            }
                            if let mode = report.mode {
                                Text("Mode: \(mode)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.04))
                        .cornerRadius(6)

                        // Checklist
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(report.items) { item in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: iconName(for: item.level))
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(iconColor(for: item.level))

                                    Text(item.message)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        .padding(.vertical, 4)

                        if let summary = report.summary {
                            Text(summary)
                                .font(.caption.bold())
                                .foregroundStyle(Color.green)
                                .padding(.top, 4)
                        }
                    }
                }
                .frame(maxHeight: 280)
            }
        }
        .padding(16)
        .frame(width: 380)
        .onAppear {
            loadReport()
        }
    }

    private func loadReport() {
        isLoading = true
        errorText = nil
        Task {
            do {
                let res = try await PortlessCLI.shared.runDoctor()
                self.report = res
                self.isLoading = false
            } catch {
                self.errorText = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    private func iconName(for level: DoctorItem.Level) -> String {
        switch level {
        case .ok: return "checkmark.circle.fill"
        case .warn: return "exclamationmark.triangle.fill"
        case .fail: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }

    private func iconColor(for level: DoctorItem.Level) -> Color {
        switch level {
        case .ok: return .green
        case .warn: return .orange
        case .fail: return .red
        case .info: return .blue
        }
    }
}
