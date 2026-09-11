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
                        withAnimation(.easeInOut(duration: 0.2)) {
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
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
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
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
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
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        TextField("Name (e.g. redis)", text: $aliasName)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))

                        TextField("Port", text: $aliasPort)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 11))
                            .frame(width: 65)

                        Button("Add") {
                            submitAlias()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(aliasName.isEmpty || aliasPort.isEmpty)

                        Button("Cancel") {
                            withAnimation {
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
                    withAnimation {
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
        guard let portNumber = Int(aliasPort), portNumber > 0, portNumber < 65536 else {
            errorMessage = "Invalid port number"
            return
        }

        let cleanName = aliasName.trimmingCharacters(in: .whitespaces)
        guard !cleanName.isEmpty else {
            errorMessage = "Alias name cannot be empty"
            return
        }

        Task {
            do {
                try await store.addAlias(name: cleanName, port: portNumber)
                withAnimation {
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
