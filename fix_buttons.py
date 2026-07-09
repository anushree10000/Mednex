import Foundation

let path = "/Users/user68/Documents/MedNex/MedNex/Features/LabTech/Views/LabTestPatientDetailView.swift"
var content = try! String(contentsOfFile: path)

content = content.replacingOccurrences(
    of: ".font(.system(.caption, design: .rounded, weight: .semibold))",
    with: ".font(.system(.subheadline, design: .rounded, weight: .bold))\n                                        .frame(maxWidth: .infinity)\n                                        .padding(.vertical, 8)"
)
content = content.replacingOccurrences(
    of: ".buttonStyle(.bordered)",
    with: ".buttonStyle(.borderedProminent)"
)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
