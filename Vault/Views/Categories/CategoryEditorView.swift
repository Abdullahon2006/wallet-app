import SwiftUI

/// Editor for creating or modifying a category.
struct CategoryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existingCategory: Category?

    @State private var name: String = ""
    @State private var colorHex: String = "#2563EB"
    @State private var iconName: String = "folder.fill"

    private let iconOptions = [
        "folder.fill", "star.fill", "heart.fill", "tag.fill",
        "cart.fill", "bag.fill", "airplane", "car.fill",
        "house.fill", "building.2.fill", "briefcase.fill", "graduationcap.fill",
        "stethoscope", "fork.knife", "cup.and.saucer.fill", "gamecontroller.fill",
    ]

    var isEditing: Bool { existingCategory != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Preview
                        HStack(spacing: 14) {
                            Image(systemName: iconName)
                                .font(.title2)
                                .foregroundStyle(Color(hex: colorHex) ?? .blue)
                                .frame(width: 48, height: 48)
                                .background((Color(hex: colorHex) ?? .blue).opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                            Text(name.isEmpty ? "Category Name" : name)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white.opacity(name.isEmpty ? 0.3 : 1))

                            Spacer()
                        }
                        .padding(16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))

                            TextField("Category name", text: $name)
                                .foregroundStyle(.white)
                                .padding(14)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }

                        // Icon
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                                ForEach(iconOptions, id: \.self) { icon in
                                    Button {
                                        iconName = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.title3)
                                            .foregroundStyle(iconName == icon ? .white : .white.opacity(0.4))
                                            .frame(width: 48, height: 48)
                                            .background(
                                                iconName == icon ?
                                                    AnyShapeStyle((Color(hex: colorHex) ?? .blue).opacity(0.3)) :
                                                    AnyShapeStyle(.white.opacity(0.06)),
                                                in: RoundedRectangle(cornerRadius: 12)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(iconName == icon ? (Color(hex: colorHex) ?? .blue) : .clear, lineWidth: 1.5)
                                            )
                                    }
                                }
                            }
                            .padding(16)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }

                        // Color
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.6))

                            CardColorPicker(selectedHex: $colorHex)
                                .padding(16)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let category = existingCategory {
                    name = category.name
                    colorHex = category.colorHex
                    iconName = category.iconName
                }
            }
        }
    }

    private func save() {
        if let category = existingCategory {
            category.name = name
            category.colorHex = colorHex
            category.iconName = iconName
        } else {
            let category = Category(name: name, colorHex: colorHex, iconName: iconName)
            modelContext.insert(category)
        }
        dismiss()
    }
}
