import SwiftUI

struct DoctorModalView: View {
    let onBack: () -> Void
    @State private var report: DoctorReport? = nil
    @State private var isLoading: Bool = true
    @State private var errorText: String? = nil

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
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 12))
                    Text("Portless Doctor")
                        .font(.system(size: 13, weight: .bold))
                }

                Spacer()

                Button {
                    loadReport()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
                .help("Rerun doctor diagnostics")
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 4)

            Divider()

            if isLoading {
                VStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Running diagnostics...")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if let error = errorText {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title3)
                        .foregroundStyle(Color.red)
                    Text("Diagnostics failed")
                        .font(.system(size: 12, weight: .semibold))
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if let report = report {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        // Environment Info
                        VStack(alignment: .leading, spacing: 2) {
                            if let v = report.version {
                                Text("Portless v\(v)").font(.system(size: 11, weight: .bold))
                            }
                            if let node = report.nodeVersion {
                                Text("Node.js: \(node)").font(.system(size: 10)).foregroundStyle(.secondary)
                            }
                            if let mode = report.mode {
                                Text("Mode: \(mode)").font(.system(size: 10)).foregroundStyle(.secondary)
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
                                        .padding(.top, 1)

                                    Text(item.message)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.vertical, 4)

                        if let summary = report.summary {
                            Text(summary)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.green)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .frame(height: 280)
            }
        }
        .padding(.bottom, 10)
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
