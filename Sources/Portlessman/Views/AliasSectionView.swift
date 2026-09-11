import SwiftUI

struct AliasSectionView: View {
    @ObservedObject var store: PortlessStore
    @State private var isAdding: Bool = false
    @State private var aliasName: String = ""
    @State private var aliasPort: String = ""
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("STATIC ALIASES (Docker / Manual Ports)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)

                Spacer()

                if !isAdding {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isAdding = true
                            errorMessage = nil
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "plus")
                                .font(.system(size: 9))
                            Text("Add")
                                .font(.system(size: 10, weight: .medium))
                        }
                    }
                    .buttonStyle(ActionPillButtonStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)

            // Static Aliases List
            if !store.staticAliases.isEmpty {
                VStack(spacing: 3) {
                    ForEach(store.staticAliases) { route in
                        HStack {
                            Circle()
                                .fill(Color.purple)
                                .frame(width: 6, height: 6)

                            Text(route.hostname)
                                .font(.system(size: 12, weight: .medium))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)

                            Text(":\(route.port)")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button {
                                Task {
                                    try? await store.removeAlias(name: route.hostname)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(HeaderIconButtonStyle())
                            .help("Remove alias")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(6)
                        .padding(.horizontal, 14)
                    }
                }
            }

            // Inline Add Form
            if isAdding {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        TextField("Name (e.g. redis)", text: $aliasName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))

                        TextField("Port", text: $aliasPort)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                            .frame(width: 65)
                            .onSubmit {
                                submitAlias()
                            }

                        Button("Add") {
                            submitAlias()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(aliasName.isEmpty || aliasPort.isEmpty)

                        Button("Cancel") {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isAdding = false
                                aliasName = ""
                                aliasPort = ""
                                errorMessage = nil
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    }

                    if let err = errorMessage {
                        Text(err)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.red)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            } else if store.staticAliases.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isAdding = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 11))
                        Text("Add new alias...")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func submitAlias() {
        let cleanName = aliasName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanName.isEmpty else {
            errorMessage = "Alias name cannot be empty"
            return
        }

        // Validate DNS name format
        let dnsRegex = "^[a-z0-9]([a-z0-9-]*[a-z0-9])?$"
        if cleanName.range(of: dnsRegex, options: .regularExpression) == nil {
            errorMessage = "Name must be alphanumeric with optional hyphens (e.g. 'my-api')"
            return
        }

        guard let portNumber = Int(aliasPort.trimmingCharacters(in: .whitespacesAndNewlines)),
              portNumber > 0 && portNumber < 65536 else {
            errorMessage = "Port must be between 1 and 65535"
            return
        }

        Task {
            do {
                try await store.addAlias(name: cleanName, port: portNumber)
                withAnimation(.easeInOut(duration: 0.15)) {
                    isAdding = false
                    aliasName = ""
                    aliasPort = ""
                    errorMessage = nil
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
