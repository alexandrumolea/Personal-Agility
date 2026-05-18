import SwiftUI
import SwiftData

struct OpportunitiesView: View {
    @Query private var opportunities: [Opportunity]
    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false
    
    private var activeOpportunities: [Opportunity] {
        opportunities
            .filter { $0.status == .active }
            .sorted { $0.amount > $1.amount }
    }
    
    private var closedOpportunities: [Opportunity] {
        opportunities
            .filter { $0.status != .active }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    private var activeTotal: Double {
        activeOpportunities.reduce(0) { $0 + $1.amount }
    }
    
    private var successRate: Double {
        let wonCount = opportunities.filter { $0.status == .won }.count
        let closedCount = opportunities.filter { $0.status == .won || $0.status == .lost }.count
        guard closedCount > 0 else { return 0 }
        return Double(wonCount) / Double(closedCount)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                List {
                    Section {
                        OpportunitySummaryView(successRate: successRate, activeTotal: activeTotal)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                    }
                    
                    if !activeOpportunities.isEmpty {
                        Section(header: sectionHeader("In Progress")) {
                            ForEach(activeOpportunities) { opportunity in
                                ZStack {
                                    NavigationLink(destination: OpportunityDetailView(opportunity: opportunity)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    
                                    OpportunityCard(opportunity: opportunity)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            }
                            .onDelete { indexSet in
                                deleteOpportunities(at: indexSet, from: activeOpportunities)
                            }
                        }
                    }
                    
                    if !closedOpportunities.isEmpty {
                        Section(header: sectionHeader("Closed")) {
                            ForEach(closedOpportunities) { opportunity in
                                ZStack {
                                    NavigationLink(destination: OpportunityDetailView(opportunity: opportunity)) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                    
                                    OpportunityCard(opportunity: opportunity)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            }
                            .onDelete { indexSet in
                                deleteOpportunities(at: indexSet, from: closedOpportunities)
                            }
                        }
                    }
                    
                    if opportunities.isEmpty {
                        ContentUnavailableView("No opportunities", systemImage: "eurosign.circle", description: Text("Add your first sales opportunity."))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .padding(.top, 50)
                    }
                    
                    Color.clear.frame(height: 80).listRowSeparator(.hidden).listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.primary)
                        .frame(width: 50, height: 50)
                        .background(.regularMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                }
                .padding(25)
            }
            .navigationTitle("Opportunities")
            .sheet(isPresented: $showAddSheet) {
                AddOpportunityView()
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2)
            .bold()
            .foregroundColor(.primary)
            .textCase(nil)
            .listRowInsets(EdgeInsets(top: 20, leading: 20, bottom: 5, trailing: 0))
    }
    
    private func deleteOpportunities(at offsets: IndexSet, from filteredList: [Opportunity]) {
        offsets.forEach { index in
            modelContext.delete(filteredList[index])
        }
    }
}

struct OpportunitySummaryView: View {
    let successRate: Double
    let activeTotal: Double
    
    var body: some View {
        HStack(spacing: 12) {
            metricCard(title: "Success Rate", value: successRate.formatted(.percent.precision(.fractionLength(0))), tint: .green)
            metricCard(title: "In Progress", value: activeTotal.formatted(.currency(code: "EUR").precision(.fractionLength(0))), tint: .blue)
        }
    }
    
    private func metricCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Capsule()
                .fill(tint.opacity(0.25))
                .frame(height: 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

struct OpportunityCard: View {
    let opportunity: Opportunity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: opportunity.status.icon)
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(opportunity.status.color)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 5) {
                Text(opportunity.name)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(opportunity.client)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if !opportunity.details.isEmpty {
                    Text(opportunity.details)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            
            Spacer(minLength: 12)
            
            VStack(alignment: .trailing, spacing: 5) {
                Text(opportunity.amount.formatted(.currency(code: "EUR").precision(.fractionLength(0))))
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(opportunity.status.rawValue)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(opportunity.status.color)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(15)
        .shadow(color: .primary.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct AddOpportunityView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var client = ""
    @State private var details = ""
    @State private var amount = 0.0
    @State private var status: OpportunityStatus = .active
    
    var body: some View {
        NavigationStack {
            OpportunityForm(name: $name, client: $client, details: $details, amount: $amount, status: $status)
                .navigationTitle("New Opportunity")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let opportunity = Opportunity(name: name, client: client, details: details, amount: amount, status: status)
                            modelContext.insert(opportunity)
                            dismiss()
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || client.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}

struct OpportunityDetailView: View {
    @Bindable var opportunity: Opportunity
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        OpportunityForm(
            name: $opportunity.name,
            client: $opportunity.client,
            details: $opportunity.details,
            amount: $opportunity.amount,
            status: $opportunity.status
        )
        .navigationTitle("Opportunity")
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(opportunity)
                    dismiss()
                }
            }
        }
    }
}

struct OpportunityForm: View {
    @Binding var name: String
    @Binding var client: String
    @Binding var details: String
    @Binding var amount: Double
    @Binding var status: OpportunityStatus
    
    var body: some View {
        Form {
            Section("Opportunity") {
                TextField("Opportunity name", text: $name)
                TextField("Client", text: $client)
                TextField("Details", text: $details, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("Value") {
                TextField("Amount in euro", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
                Picker("Status", selection: $status) {
                    ForEach(OpportunityStatus.allCases, id: \.self) { status in
                        Label(status.rawValue, systemImage: status.icon).tag(status)
                    }
                }
            }
        }
    }
}

private extension OpportunityStatus {
    var color: Color {
        switch self {
        case .active: return .blue
        case .lost: return .red
        case .won: return .green
        }
    }
    
    var icon: String {
        switch self {
        case .active: return "clock.fill"
        case .lost: return "xmark"
        case .won: return "checkmark"
        }
    }
}
