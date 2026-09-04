import SwiftUI
import SwiftData

/// List of user-defined categories with cards count.
struct CategoriesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]
    @State private var showEditor: Bool = false
    @State private var editingCategory: Category?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.06, blue: 0.12)
                    .ignoresSafeArea()

                if categories.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(categories) { category in
                            categoryRow(category)
                                .listRowBackground(Color.white.opacity(0.04))
                                .listRowSeparatorTint(.white.opacity(0.1))
                                .onTapGesture {
                                    editingCategory = category
                                }
                        }
                        .onDelete(perform: deleteCategories)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Categories")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showEditor = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                CategoryEditorView()
            }
            .sheet(item: $editingCategory) { category in
                CategoryEditorView(existingCategory: category)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.fill")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.3))

            Text("No Categories")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text("Create categories to organise your cards")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            Button {
                showEditor = true
            } label: {
                Label("New Category", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(hex: "#4F46E5")!, in: Capsule())
            }
            .padding(.top, 4)
        }
    }

    private func categoryRow(_ category: Category) -> some View {
        HStack(spacing: 14) {
            Image(systemName: category.iconName)
                .font(.title3)
                .foregroundStyle(category.color)
                .frame(width: 40, height: 40)
                .background(category.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("\(category.cards.count) card\(category.cards.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.vertical, 4)
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
    }
}
