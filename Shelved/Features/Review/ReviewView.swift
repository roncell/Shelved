import SwiftUI

struct ReviewView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: ReviewViewModel

    init(id: MediaID, library: any LibraryRepository = SwiftDataLibraryRepository.shared) {
        _viewModel = State(initialValue: ReviewViewModel(id: id, library: library))
    }

    var body: some View {
        content
            .navigationTitle("Your Notes")
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                "Couldn't save",
                isPresented: Binding(
                    get: { viewModel.saveError != nil },
                    set: { if !$0 { viewModel.saveError = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.saveError ?? "")
            }
            .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .failed(let error):
            ContentUnavailableView {
                Label("Couldn't open your notes", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.userMessage)
            }

        case .loaded(let item):
            form(title: item.media.title)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                if await viewModel.save() { router.pop() }
                            }
                        }
                        .disabled(!viewModel.canSave)
                    }
                }
        }
    }

    private func form(title: String) -> some View {
        Form {
            Section {
                Text(title).font(.headline)
            }

            Section("Rating") {
                RatingPicker(rating: $viewModel.log.rating)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if viewModel.log.rating != nil {
                    Button("Clear Rating", role: .destructive) {
                        viewModel.log.rating = nil
                    }
                }
            }

            Section("Progress") {
                LabeledContent("Current page") {
                    numberField("Page", value: $viewModel.log.progress)
                }
                LabeledContent("Total pages") {
                    numberField("Pages", value: $viewModel.log.progressTotal)
                }
            }

            Section("Dates") {
                optionalDatePicker("Started", date: $viewModel.log.startedAt)
                optionalDatePicker("Finished", date: $viewModel.log.finishedAt)
            }

            Section("Review") {
                TextEditor(text: $viewModel.log.review)
                    .frame(minHeight: 140)
                    .accessibilityLabel(Text("Review"))
            }

            if !viewModel.log.validationErrors.isEmpty {
                Section {
                    ForEach(viewModel.log.validationErrors, id: \.self) { message in
                        Label(message, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    /// A number pad field for an optional Int: empty text means nil.
    private func numberField(_ placeholder: LocalizedStringKey, value: Binding<Int?>) -> some View {
        TextField(placeholder, text: Binding(
            get: { value.wrappedValue.map(String.init) ?? "" },
            set: { value.wrappedValue = Int($0.filter(\.isNumber)) }
        ))
        .keyboardType(.numberPad)
        .multilineTextAlignment(.trailing)
        .frame(maxWidth: 100)
    }

    /// A toggle that reveals a date picker: off means "no date".
    @ViewBuilder
    private func optionalDatePicker(_ title: LocalizedStringKey, date: Binding<Date?>) -> some View {
        Toggle(title, isOn: Binding(
            get: { date.wrappedValue != nil },
            set: { date.wrappedValue = $0 ? (date.wrappedValue ?? .now) : nil }
        ))
        if let current = date.wrappedValue {
            DatePicker(
                title,
                selection: Binding(get: { current }, set: { date.wrappedValue = $0 }),
                in: ...Date.now,
                displayedComponents: .date
            )
            .labelsHidden()
        }
    }
}

#Preview {
    NavigationStack {
        ReviewView(id: PreviewCatalog.items[0].id, library: SwiftDataLibraryRepository.preview())
    }
    .environment(Router())
}
