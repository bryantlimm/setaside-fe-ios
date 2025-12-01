//
//  AddEditProductView.swift
//  SetAside
//

import SwiftUI

struct AddEditProductView: View {
    @ObservedObject var viewModel: AdminProductViewModel
    let product: Product?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var priceText: String = ""
    @State private var stockText: String = ""
    @State private var category: String = ""
    @State private var isAvailable: Bool = true
    @State private var imageUrl: String = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var isEditing: Bool {
        product != nil
    }
    
    var isFormValid: Bool {
        !name.isEmpty && 
        !description.isEmpty && 
        Double(priceText) != nil && 
        Int(stockText) != nil && 
        !category.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Info Section
                Section("Basic Information") {
                    TextField("Product Name", text: $name)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .textContentType(.none)
                    
                    // Category picker
                    if viewModel.categories.isEmpty {
                        TextField("Category", text: $category)
                            .textContentType(.none)
                            .autocorrectionDisabled()
                    } else {
                        Picker("Category", selection: $category) {
                            Text("Select Category").tag("")
                            ForEach(viewModel.categories, id: \.self) { cat in
                                Text(cat.capitalized).tag(cat)
                            }
                        }
                    }
                }
                
                // Image URL Section
                Section("Product Image") {
                    TextField("Image URL", text: $imageUrl)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    if !imageUrl.isEmpty, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 150)
                                    .cornerRadius(8)
                            case .failure(_):
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.orange)
                                    Text("Invalid image URL")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            case .empty:
                                ProgressView()
                                    .frame(height: 100)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                
                // Pricing Section
                Section("Pricing & Stock") {
                    HStack {
                        Text("$")
                        TextField("Price", text: $priceText)
                            .keyboardType(.decimalPad)
                            .textContentType(.none)
                    }
                    
                    TextField("Stock Quantity", text: $stockText)
                        .keyboardType(.numberPad)
                        .textContentType(.none)
                }
                
                // Availability Section
                Section("Availability") {
                    Toggle("Available for Sale", isOn: $isAvailable)
                }
                
                // Save Button
                Section {
                    Button {
                        Task {
                            await saveProduct()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Saving...")
                            } else {
                                Text(isEditing ? "Update Product" : "Create Product")
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                    .foregroundColor(isFormValid && !viewModel.isLoading ? .white : .gray)
                    .listRowBackground(isFormValid && !viewModel.isLoading ? Color.green : Color.gray.opacity(0.3))
                }
            }
            .navigationTitle(isEditing ? "Edit Product" : "Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isSuccess ? "Success" : "Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {
                    if isSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadProductData()
            }
        }
    }
    
    private func loadProductData() {
        if let product = product {
            name = product.name
            description = product.description ?? ""
            priceText = String(format: "%.2f", product.price)
            stockText = String(product.stockQuantity ?? 0)
            category = product.category
            isAvailable = product.isAvailable
            imageUrl = product.imageUrl ?? ""
        } else if let firstCategory = viewModel.categories.first {
            category = firstCategory
        }
    }
    
    private func saveProduct() async {
        guard let price = Double(priceText),
              let stockQuantity = Int(stockText) else {
            alertMessage = "Please enter valid price and stock values"
            isSuccess = false
            showAlert = true
            return
        }
        
        var success: Bool
        let trimmedImageUrl = imageUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let product = product {
            // Update existing product
            success = await viewModel.updateProduct(
                id: product.id,
                name: name,
                description: description,
                price: price,
                stockQuantity: stockQuantity,
                category: category,
                isAvailable: isAvailable,
                imageUrl: trimmedImageUrl.isEmpty ? nil : trimmedImageUrl
            )
        } else {
            // Create new product
            success = await viewModel.createProduct(
                name: name,
                description: description,
                price: price,
                stockQuantity: stockQuantity,
                category: category,
                isAvailable: isAvailable,
                imageUrl: trimmedImageUrl.isEmpty ? nil : trimmedImageUrl
            )
        }
        
        if success {
            alertMessage = isEditing ? "Product updated successfully" : "Product created successfully"
            isSuccess = true
        } else {
            alertMessage = viewModel.errorMessage ?? "An error occurred"
            isSuccess = false
        }
        showAlert = true
    }
}

#Preview {
    AddEditProductView(viewModel: AdminProductViewModel(), product: nil)
}
