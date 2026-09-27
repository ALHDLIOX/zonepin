import SwiftUI

struct TimeZonePickerView: View {
    let selectedIdentifier: String
    let onSelect: (String) -> Void

    @State private var searchText = ""

    private let identifiers = TimeZone.knownTimeZoneIdentifiers.sorted()
    private let englishLocale = Locale(identifier: "en_US")

    private var filteredIdentifiers: [String] {
        let search = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else { return identifiers }

        return identifiers.filter { identifier in
            guard let zone = TimeZone(identifier: identifier) else { return false }
            let searchable = [
                identifier,
                identifier.replacingOccurrences(of: "_", with: " "),
                zone.localizedName(for: .generic, locale: englishLocale) ?? "",
                ClockFormatter.utcOffset(for: zone, at: Date()),
                identifier == "Asia/Shanghai" ? "Beijing China" : ""
            ].joined(separator: " ")
            return searchable.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Time Zone")
                .font(.title2.weight(.semibold))

            TextField("Search city, region, or UTC offset", text: $searchText)
                .textFieldStyle(.roundedBorder)

            Text("Selected: \(selectedIdentifier)")
                .font(.caption)
                .foregroundColor(.secondary)

            List(filteredIdentifiers, id: \.self) { identifier in
                if let zone = TimeZone(identifier: identifier) {
                    Button {
                        onSelect(identifier)
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(identifier == "Asia/Shanghai" ? "Asia/Shanghai (Beijing)" : identifier)
                                    .font(.body)
                                Text(zone.localizedName(for: .generic, locale: englishLocale) ?? identifier)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer(minLength: 8)
                            Text(ClockFormatter.utcOffset(for: zone, at: Date()))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                            if identifier == selectedIdentifier {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.inset)
        }
        .padding(18)
        .frame(minWidth: 460, minHeight: 430)
    }
}
