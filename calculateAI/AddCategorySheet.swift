import SwiftData
import SwiftUI

struct AddCategorySheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var budget: String = ""
    @State private var selectedIcon: String = "cart.fill"
    @State private var showingIconPicker = false

    var body: some View {
        ZStack {
            Color.zenithBlack.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("New Category")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 20)

                // Icon Selector
                Button(action: { showingIconPicker = true }) {
                    VStack {
                        Image(systemName: selectedIcon)
                            .font(.system(size: 40))
                            .foregroundColor(.neonTurquoise)
                            .padding()
                            .background(Circle().fill(Color.white.opacity(0.1)))

                        Text("Tap to change icon")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                VStack(spacing: 16) {
                    // Name Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category Name")
                            .font(.caption)
                            .foregroundColor(.gray)

                        TextField("Name", text: $name)
                            .foregroundColor(.white)
                            .font(.title3)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }

                    // Budget Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Limit")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack {
                            Text("$")
                                .foregroundColor(.gray)
                                .font(.title3)

                            TextField("Budget", text: $budget)
                                .keyboardType(.decimalPad)
                                .foregroundColor(.white)
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: saveCategory) {
                        Text("Create Category")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.mintGreen : Color.gray)
                            .cornerRadius(16)
                    }
                    .disabled(!isFormValid)

                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .sheet(isPresented: $showingIconPicker) {
            IconPickerView { icon in
                selectedIcon = icon
                showingIconPicker = false
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && Double(budget) != nil
    }

    private func saveCategory() {
        guard let budgetValue = Double(budget) else { return }

        let newCategory = CategoryModel(
            id: UUID().uuidString,
            name: name,
            icon: selectedIcon,
            budgetLimit: budgetValue,
            orderIndex: 999  // Append to end
        )

        modelContext.insert(newCategory)
        dismiss()
    }
}
