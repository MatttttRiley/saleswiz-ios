import SwiftUI

// MARK: - Shared components

struct StatusBadge: View {
    let status: LeadStatus

    var body: some View {
        Text(status.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.15))
            .foregroundStyle(status.color)
            .clipShape(Capsule())
    }
}

struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ProgressBarView: View {
    let percent: Int
    let stage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(percent)%")
                    .font(.title.weight(.bold))
                Text(stage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.salesNavy)
                        .frame(width: max(12, geometry.size.width * CGFloat(percent) / 100))
                }
            }
            .frame(height: 12)
        }
        .padding(.vertical, 4)
    }
}

struct PriorityBadge: View {
    let priority: Int

    var body: some View {
        Text("★ Priority \(priority)")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.15))
            .foregroundStyle(.green)
            .clipShape(Capsule())
    }
}

struct OpensBadge: View {
    let count: Int

    var body: some View {
        Text("Opened ×\(count)")
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.12))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
    }
}

struct LeadRow: View {
    let lead: Lead

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: Industry.icon(for: lead.industry))
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(lead.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(lead.displayCity)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if let due = lead.followUpDue?.dueText {
                    Text(due)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                StatusBadge(status: lead.statusInfo)
                if let priority = lead.priority, priority > 0 {
                    PriorityBadge(priority: priority)
                }
                if let opens = lead.openCount, opens > 0 {
                    OpensBadge(count: opens)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Dashboard

struct DashboardView: View {
    @EnvironmentObject var api: APIClient
    @State private var dashboard: Dashboard?
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showSignOut = false

    var body: some View {
        Group {
            if let dashboard {
                List {
                    Section {
                        ProgressBarView(
                            percent: dashboard.progress?.percent ?? 0,
                            stage: dashboard.progress?.stage ?? "Outreach"
                        )
                        if let eta = dashboard.eta {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("First customer in \(eta.rangeText)")
                                    .font(.headline)
                                Text(eta.likelyText)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let emailDays = eta.emailDays, let callDays = eta.callDays {
                                    Text("Email path \(emailDays.text) · Call path \(callDays.text)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if eta.stalled == true {
                                    Label("No replies after 200+ delivered — the pitch or targeting needs a look.", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    } header: {
                        Text("Time to first sale")
                    }

                    Section("Funnel") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            StatTile(value: "\(dashboard.total ?? 0)", label: "Leads")
                            StatTile(value: "\(dashboard.sent ?? 0)", label: "Sent")
                            StatTile(value: "\(dashboard.delivered ?? 0)", label: "Delivered")
                            StatTile(value: "\(dashboard.replies ?? 0)", label: "Replies")
                            StatTile(value: "\(dashboard.interested ?? 0)", label: "Interested")
                            StatTile(value: "\(dashboard.demos ?? 0)", label: "Demos")
                            StatTile(value: "\(dashboard.customers ?? 0)", label: "Customers")
                            StatTile(value: "\(dashboard.bounced ?? 0)", label: "Bounced")
                            StatTile(value: "\(dashboard.notContacted ?? 0)", label: "Not contacted")
                            StatTile(value: "\(dashboard.emailsOpened ?? 0)", label: "Emails opened")
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    Section("Money") {
                        LabeledContent("Setup collected") {
                            Text("$\(dashboard.money?.setupCollected ?? 0)")
                        }
                        LabeledContent("Monthly recurring") {
                            Text("$\(dashboard.money?.mrr ?? 0)/mo")
                        }
                        LabeledContent("Price") {
                            Text("$\(dashboard.money?.setupFee ?? 500) setup · $\(dashboard.money?.monthlyFee ?? 100)/mo")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Today") {
                        LabeledContent("Calls left") {
                            Text("\(dashboard.callsLeftToday ?? 0) of 10")
                        }
                        LabeledContent("Follow-ups due") {
                            Text("\(dashboard.followupsDue ?? 0)")
                        }
                        LabeledContent("In call queue") {
                            Text("\(dashboard.inCallQueue ?? 0)")
                        }
                        LabeledContent("Email leads left") {
                            Text("\(dashboard.remainingEmail ?? 0)")
                        }
                    }

                    if let byIndustry = dashboard.byIndustry, !byIndustry.isEmpty {
                        Section("By industry") {
                            ForEach(byIndustry.sorted(by: { ($0.value.total ?? 0) > ($1.value.total ?? 0) }), id: \.key) { industry, stats in
                                HStack {
                                    Image(systemName: Industry.icon(for: industry))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24)
                                    Text(Industry.label(for: industry))
                                    Spacer()
                                    Text("\(stats.delivered ?? 0) sent · \(stats.replies ?? 0) replies")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section {
                        Button("Sign Out", role: .destructive) { showSignOut = true }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await load() }
                .confirmationDialog("Sign out?", isPresented: $showSignOut) {
                    Button("Sign Out", role: .destructive) { api.logout() }
                    Button("Cancel", role: .cancel) {}
                }
            } else if isLoading {
                ProgressView("Loading…")
            } else {
                ContentUnavailableView {
                    Label("Couldn't load the dashboard", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(errorMessage ?? "Something went wrong.")
                } actions: {
                    Button("Try Again") { Task { await load() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Dashboard")
        .task { await load() }
    }

    private func load() async {
        if dashboard == nil { isLoading = true }
        errorMessage = nil
        do {
            dashboard = try await api.fetchDashboard()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Leads

struct LeadsView: View {
    @EnvironmentObject var api: APIClient
    @State private var leads: [Lead] = []
    @State private var total = 0
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var statusFilter: String?
    @State private var industryFilter: String?
    @State private var showAddLead = false

    private var filterKey: String {
        "\(searchText)|\(statusFilter ?? "")|\(industryFilter ?? "")"
    }

    var body: some View {
        List {
            ForEach(leads) { lead in
                NavigationLink(value: lead) {
                    LeadRow(lead: lead)
                        .onAppear {
                            if lead == leads.last { Task { await loadMore() } }
                        }
                }
            }
            if isLoadingMore {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .listRowSeparator(.hidden)
            }
            if !isLoading && leads.isEmpty && errorMessage == nil {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Leads")
        .navigationDestination(for: Lead.self) { lead in
            LeadDetailView(leadId: lead.id)
        }
        .searchable(text: $searchText, prompt: "Search name, city, email, phone")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Status", selection: $statusFilter) {
                        Text("All statuses").tag(String?.none)
                        ForEach(LeadStatus.allCases, id: \.rawValue) { status in
                            Text(status.label).tag(String?.some(status.rawValue))
                        }
                    }
                } label: {
                    Label("Status", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Industry", selection: $industryFilter) {
                        Text("All industries").tag(String?.none)
                        ForEach(Industry.all, id: \.self) { industry in
                            Text(Industry.label(for: industry)).tag(String?.some(industry))
                        }
                    }
                } label: {
                    Label("Industry", systemImage: "tag")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddLead = true } label: {
                    Label("Add Lead", systemImage: "plus")
                }
            }
        }
        .refreshable { await reload() }
        .task(id: filterKey) {
            // Debounce typing; .task(id:) cancels the previous task on change.
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            await reload()
        }
        .sheet(isPresented: $showAddLead) {
            AddLeadView { _ in Task { await reload() } }
        }
        .alert("Couldn't load leads", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func reload() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await api.fetchLeads(
                search: searchText, industry: industryFilter, status: statusFilter,
                limit: 100, offset: 0)
            leads = response.leads
            total = response.total
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func loadMore() async {
        guard !isLoadingMore, leads.count < total else { return }
        isLoadingMore = true
        do {
            let response = try await api.fetchLeads(
                search: searchText, industry: industryFilter, status: statusFilter,
                limit: 100, offset: leads.count)
            leads += response.leads
            total = response.total
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoadingMore = false
    }
}

// MARK: - Lead detail

struct LeadDetailView: View {
    @EnvironmentObject var api: APIClient
    let leadId: Int
    @State private var lead: Lead?
    @State private var emails: [EmailMessage] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showLogCall = false
    @State private var showLogReply = false
    @State private var showBounceConfirm = false
    @State private var showStatusPicker = false

    var body: some View {
        Group {
            if let lead {
                List {
                    Section {
                        HStack {
                            Image(systemName: Industry.icon(for: lead.industry))
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lead.displayCity)
                                    .font(.subheadline)
                                if let person = lead.contactPerson, !person.isEmpty {
                                    Text("Contact: \(person)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            StatusBadge(status: lead.statusInfo)
                        }
                        if let phone = lead.phone, !phone.isEmpty {
                            HStack {
                                Label(phone, systemImage: "phone.fill")
                                Spacer()
                                if let url = lead.telURL {
                                    Link("Call", destination: url)
                                }
                            }
                        }
                        if let email = lead.email, !email.isEmpty {
                            HStack {
                                Label(email, systemImage: "envelope.fill")
                                Spacer()
                                if let url = lead.mailURL {
                                    Link("Email", destination: url)
                                }
                            }
                        }
                        if let source = lead.source, !source.isEmpty, let url = URL(string: source) {
                            Link(destination: url) {
                                Label("Website", systemImage: "globe")
                            }
                        }
                    }

                    Section("Details") {
                        LabeledContent("Status") { Text(lead.statusInfo.label) }
                        if let priority = lead.priority, priority > 0 {
                            LabeledContent("Priority") {
                                Text("★ \(priority)")
                                    .foregroundStyle(.green)
                            }
                        }
                        if let opens = lead.opens {
                            LabeledContent("Email opens") {
                                if let count = opens.count, count > 0 {
                                    Text("Opened — \(count) time\(count == 1 ? "" : "s")\(opens.lastAt.map { " · last \($0.prettyDateTime)" } ?? "")")
                                        .multilineTextAlignment(.trailing)
                                } else {
                                    Text("Not opened yet")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        if let emailed = lead.dateEmailed {
                            LabeledContent("Emailed") { Text(emailed.prettyDate) }
                        }
                        if let called = lead.dateCalled {
                            LabeledContent("Called") { Text(called.prettyDate) }
                        }
                        if let outcome = lead.callOutcome, !outcome.isEmpty {
                            LabeledContent("Call outcome") { Text(outcome) }
                        }
                        if let replied = lead.dateReplied {
                            LabeledContent("Replied") { Text(replied.prettyDate) }
                        }
                        if let due = lead.followUpDue {
                            LabeledContent("Follow-up") {
                                Text(due.dueText ?? due.prettyDate)
                                    .foregroundStyle(.orange)
                            }
                        }
                        if let notes = lead.notes, !notes.isEmpty {
                            Text(notes)
                        }
                        if let services = lead.servicesBought, !services.isEmpty {
                            LabeledContent("Services") { Text(services) }
                        }
                        if let grok = lead.grokSetupStatus, !grok.isEmpty {
                            LabeledContent("Grok setup") { Text(grok) }
                        }
                    }

                    if !emails.isEmpty {
                        Section("Emails") {
                            ForEach(emails) { message in
                                NavigationLink {
                                    EmailDetailView(email: message)
                                } label: {
                                    EmailRow(email: message)
                                }
                            }
                        }
                    }

                    if let history = lead.history, !history.isEmpty {
                        Section("History") {
                            ForEach(history) { event in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: event.icon)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.detail)
                                            .font(.subheadline)
                                        if let date = event.eventDate {
                                            Text(date.prettyDate)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button { showLogCall = true } label: {
                                Label("Log a Call", systemImage: "phone.fill")
                            }
                            Button { showLogReply = true } label: {
                                Label("Log a Reply", systemImage: "arrowshape.turn.up.left.fill")
                            }
                            Menu("Change Status") {
                                ForEach(LeadStatus.settable, id: \.rawValue) { status in
                                    Button(status.label) {
                                        Task { await changeStatus(to: status) }
                                    }
                                }
                            }
                            Button("Record Bounce", role: .destructive) {
                                showBounceConfirm = true
                            }
                        } label: {
                            Label("Actions", systemImage: "ellipsis.circle")
                        }
                    }
                }
                .sheet(isPresented: $showLogCall) {
                    LogCallSheet(lead: lead) { updated in
                        self.lead = updated
                    }
                }
                .sheet(isPresented: $showLogReply) {
                    LogReplySheet(lead: lead) { updated in
                        self.lead = updated
                    }
                }
                .confirmationDialog(
                    "Record a bounce for this lead?",
                    isPresented: $showBounceConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Record Bounce", role: .destructive) {
                        Task { await recordBounce() }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("The lead is marked bounced and do-not-contact, and the address can never be re-added.")
                }
            } else if isLoading {
                ProgressView("Loading…")
            } else {
                ContentUnavailableView {
                    Label("Couldn't load this lead", systemImage: "person.crop.circle.badge.exclamationmark")
                } description: {
                    Text(errorMessage ?? "Something went wrong.")
                } actions: {
                    Button("Try Again") { Task { await load() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle(lead?.name ?? "Lead")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        if lead == nil { isLoading = true }
        errorMessage = nil
        do {
            lead = try await api.fetchLead(id: leadId)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        // The email thread is nice to have, not load-blocking: a failure
        // just leaves the section out.
        if let fetched = try? await api.fetchEmails(leadId: leadId, limit: 50) {
            emails = fetched.emails
        }
        isLoading = false
    }

    private func changeStatus(to status: LeadStatus) async {
        do {
            lead = try await api.updateLeadStatus(leadId: leadId, status: status.rawValue)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }

    private func recordBounce() async {
        do {
            lead = try await api.recordBounce(leadId: leadId, reason: nil)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// MARK: - Log a call / log a reply

struct LogCallSheet: View {
    @EnvironmentObject var api: APIClient
    let lead: Lead
    let onSaved: (Lead) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var outcome = "no answer"
    @State private var note = ""
    @State private var addFollowUp = false
    @State private var followUpDate = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let outcomes = ["no answer", "hung up", "not interested", "interested", "voicemail", "callback requested"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Outcome") {
                    Picker("Outcome", selection: $outcome) {
                        ForEach(outcomes, id: \.self) { outcome in
                            Text(outcome.capitalized).tag(outcome)
                        }
                    }
                    .pickerStyle(.inline)
                }
                Section("Note") {
                    TextField("What happened on the call? (optional)", text: $note, axis: .vertical)
                }
                Section("Follow-up") {
                    Toggle("Set a follow-up", isOn: $addFollowUp)
                    if addFollowUp {
                        DatePicker("Follow up on", selection: $followUpDate, displayedComponents: .date)
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Log a Call")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            let updated = try await api.logCall(
                leadId: lead.id, outcome: outcome,
                note: note.isEmpty ? nil : note,
                followUpDue: addFollowUp ? followUpDate.dayString : nil)
            onSaved(updated)
            dismiss()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isSaving = false
    }
}

struct LogReplySheet: View {
    @EnvironmentObject var api: APIClient
    let lead: Lead
    let onSaved: (Lead) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var note = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Reply") {
                    Text("Mark this lead as replied. The follow-up is cleared.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("Note (optional)", text: $note, axis: .vertical)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Log a Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            let updated = try await api.logReply(leadId: lead.id, note: note.isEmpty ? nil : note)
            onSaved(updated)
            dismiss()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Actions (daily queue)

struct ActionsView: View {
    @EnvironmentObject var api: APIClient
    @State private var actions: ActionsList?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var queueAlert: String?

    var body: some View {
        Group {
            if let actions {
                List {
                    Section {
                        LabeledContent("Calls left today") {
                            Text("\(actions.callsLeftToday ?? 0) of 10")
                        }
                    }

                    Section("Follow-ups due (\(actions.followups?.count ?? 0))") {
                        if let followups = actions.followups, !followups.isEmpty {
                            ForEach(followups) { item in
                                NavigationLink(value: item.id) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name ?? "")
                                            .font(.headline)
                                        Text([item.city, item.industry].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if let due = item.followUpDue?.dueText {
                                        Text(due)
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                        } else {
                            Text("Nothing due. Nice.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Call queue (\(actions.callQueue?.count ?? 0))") {
                        if let queue = actions.callQueue, !queue.isEmpty {
                            ForEach(queue) { item in
                                HStack {
                                    NavigationLink(value: item.id) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name ?? "")
                                                .font(.headline)
                                            Text([item.city, item.industry].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    Spacer()
                                    if let url = item.telURL {
                                        Link(destination: url) {
                                            Image(systemName: "phone.fill")
                                                .foregroundStyle(Color.salesNavy)
                                                .padding(8)
                                                .background(Color.salesNavy.opacity(0.12))
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        } else {
                            Text("The call queue is empty.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Next batch (\(actions.nextBatch?.count ?? 0))") {
                        if let batch = actions.nextBatch, !batch.isEmpty {
                            ForEach(batch) { item in
                                NavigationLink(value: item.id) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.name ?? "")
                                            .font(.headline)
                                        Text([item.city, item.industry].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } else {
                            Text("No email leads left in the pool.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section {
                        Button("Queue Next Batch of 20") {
                            Task { await queueNextBatch() }
                        }
                    } footer: {
                        Text("Queues the next 20 not-contacted leads that have an email, as the next email batch.")
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await load() }
                .navigationDestination(for: Int.self) { id in
                    LeadDetailView(leadId: id)
                }
                .alert("Batch queued", isPresented: .constant(queueAlert != nil)) {
                    Button("OK") { queueAlert = nil }
                } message: {
                    Text(queueAlert ?? "")
                }
            } else if isLoading {
                ProgressView("Loading…")
            } else {
                ContentUnavailableView {
                    Label("Couldn't load today's actions", systemImage: "checklist")
                } description: {
                    Text(errorMessage ?? "Something went wrong.")
                } actions: {
                    Button("Try Again") { Task { await load() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Actions")
        .task { await load() }
    }

    private func load() async {
        if actions == nil { isLoading = true }
        errorMessage = nil
        do {
            actions = try await api.fetchActions()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func queueNextBatch() async {
        do {
            let result = try await api.queueBatch()
            queueAlert = "Batch \(result.batch ?? 0): \(result.queued ?? 0) leads queued."
            await load()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// MARK: - Call List (Matt's own calls)

struct CallOutcomeOption: Identifiable {
    let value: String
    let label: String
    var id: String { value }

    static let all: [CallOutcomeOption] = [
        CallOutcomeOption(value: "interested", label: "Successful — interested"),
        CallOutcomeOption(value: "callback", label: "Callback requested"),
        CallOutcomeOption(value: "no_answer", label: "No answer"),
        CallOutcomeOption(value: "gatekeeper", label: "Gatekeeper / left message"),
        CallOutcomeOption(value: "not_interested", label: "Not interested"),
        CallOutcomeOption(value: "wrong_number", label: "Wrong number"),
        CallOutcomeOption(value: "other", label: "Other"),
    ]
}

struct CallListRow: View {
    let lead: Lead
    let onLogOutcome: (Lead) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lead.name)
                        .font(.headline)
                        .lineLimit(2)
                    Text([lead.industry.map { Industry.label(for: $0) }, lead.city, lead.contactPerson]
                        .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: lead.statusInfo)
                    if let priority = lead.priority, priority > 0 {
                        PriorityBadge(priority: priority)
                    }
                }
            }

            if let phone = lead.phone, !phone.isEmpty, let url = lead.telURL {
                Link(destination: url) {
                    Label(phone, systemImage: "phone.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.salesNavy)
                }
                .buttonStyle(.plain)
            }

            if let email = lead.email, !email.isEmpty {
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let last = lead.lastHistory, let text = last.text, !text.isEmpty {
                Text("Last: \(last.createdAt ?? "") — \(text)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            } else if let called = lead.dateCalled {
                Text("Last call: \(called.prettyDate)\(lead.callOutcome.map { " — \($0)" } ?? "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let follow = lead.followUpDue, !follow.isEmpty {
                Text("Follow-up: \(follow)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.orange)
            }

            HStack {
                Button {
                    onLogOutcome(lead)
                } label: {
                    Label("Log outcome", systemImage: "checklist")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(Color.salesNavy)
                Spacer()
                NavigationLink(value: lead) {
                    Text("Details")
                        .font(.subheadline)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct CallListView: View {
    @EnvironmentObject var api: APIClient
    @State private var leads: [Lead] = []
    @State private var total = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var loggingLead: Lead?

    private var filtered: [Lead] {
        guard !searchText.isEmpty else { return leads }
        let needle = searchText.lowercased()
        return leads.filter {
            $0.name.lowercased().contains(needle)
                || ($0.city ?? "").lowercased().contains(needle)
                || ($0.industry ?? "").lowercased().contains(needle)
                || ($0.phone ?? "").contains(searchText)
        }
    }

    var body: some View {
        Group {
            if !leads.isEmpty {
                List {
                    Section {
                        ForEach(filtered) { lead in
                            CallListRow(lead: lead) { selected in
                                loggingLead = selected
                            }
                        }
                    } header: {
                        Text("\(total) businesses to call")
                    } footer: {
                        Text("Tap a number to call. Log the outcome right after — a successful call pushes the lead to the top of the CRM.")
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await load() }
            } else if isLoading {
                ProgressView("Loading…")
            } else {
                ContentUnavailableView {
                    Label("No businesses on the list", systemImage: "phone")
                } description: {
                    Text(errorMessage ?? "The St. George-area call list is empty.")
                } actions: {
                    Button("Try Again") { Task { await load() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Call List")
        .navigationDestination(for: Lead.self) { lead in
            LeadDetailView(leadId: lead.id)
        }
        .searchable(text: $searchText, prompt: "Search name, city, phone")
        .task { await load() }
        .sheet(item: $loggingLead) { lead in
            LogCallOutcomeSheet(lead: lead) {
                Task { await load() }
            }
        }
        .alert("Couldn't load the call list", isPresented: .constant(errorMessage != nil && !leads.isEmpty)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func load() async {
        if leads.isEmpty { isLoading = true }
        errorMessage = nil
        do {
            let response = try await api.fetchCallList()
            leads = response.leads
            total = response.total
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}

struct LogCallOutcomeSheet: View {
    @EnvironmentObject var api: APIClient
    let lead: Lead
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var outcome = "interested"
    @State private var notes = ""
    @State private var email = ""
    @State private var followUp = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Outcome") {
                    Picker("Outcome", selection: $outcome) {
                        ForEach(CallOutcomeOption.all) { option in
                            Text(option.label).tag(option.value)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section("Notes") {
                    TextField("Who you spoke to, what they said…", text: $notes, axis: .vertical)
                }
                Section("Email") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                if outcome == "interested" || outcome == "callback" {
                    Section("Discussion time") {
                        TextField("e.g. Thu 2pm, or 2026-11-14", text: $followUp)
                            .autocorrectionDisabled()
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(lead.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save call") { Task { await save() } }
                        .disabled(isSaving)
                }
            }
            .onAppear {
                if email.isEmpty { email = lead.email ?? "" }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            _ = try await api.logCallOutcome(
                leadId: lead.id, outcome: outcome,
                notes: notes.isEmpty ? nil : notes,
                email: email.isEmpty ? nil : email,
                followUp: followUp.isEmpty ? nil : followUp)
            onSaved()
            dismiss()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Add a lead

struct AddLeadView: View {
    @EnvironmentObject var api: APIClient
    let onSaved: (Lead) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var industry = "plumber"
    @State private var city = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var contactPerson = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Business") {
                    TextField("Business name", text: $name)
                    Picker("Industry", selection: $industry) {
                        ForEach(Industry.all, id: \.self) { industry in
                            Text(Industry.label(for: industry)).tag(industry)
                        }
                    }
                    TextField("City", text: $city)
                }
                Section("Contact") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Contact person", text: $contactPerson)
                }
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Lead")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            let lead = try await api.addLead(
                name: name.trimmingCharacters(in: .whitespaces),
                industry: industry,
                city: city.isEmpty ? nil : city,
                phone: phone.isEmpty ? nil : phone,
                email: email.isEmpty ? nil : email,
                contactPerson: contactPerson.isEmpty ? nil : contactPerson,
                notes: notes.isEmpty ? nil : notes)
            onSaved(lead)
            dismiss()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Inbox

struct EmailBadge: View {
    let email: EmailMessage

    var body: some View {
        Text(email.badgeLabel)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(email.badgeColor.opacity(0.15))
            .foregroundStyle(email.badgeColor)
            .clipShape(Capsule())
    }
}

struct EmailRow: View {
    let email: EmailMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                EmailBadge(email: email)
                Text(email.leadName ?? email.counterpart)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if let received = email.receivedAt {
                    Text(received.prettyDateTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(email.subject ?? "(no subject)")
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
            if let body = email.body, !body.isEmpty {
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

struct InboxView: View {
    @EnvironmentObject var api: APIClient
    @State private var emails: [EmailMessage] = []
    @State private var total = 0
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var showCompose = false

    var body: some View {
        Group {
            if !emails.isEmpty {
                List {
                    ForEach(emails) { email in
                        NavigationLink {
                            EmailDetailView(email: email)
                        } label: {
                            EmailRow(email: email)
                                .onAppear {
                                    if email == emails.last { Task { await loadMore() } }
                                }
                        }
                    }
                    if isLoadingMore {
                        HStack { Spacer(); ProgressView(); Spacer() }
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await reload() }
            } else if isLoading {
                ProgressView("Loading…")
            } else {
                ContentUnavailableView {
                    Label("No emails yet", systemImage: "envelope")
                } description: {
                    Text(errorMessage ?? "Replies to outreach will show up here.")
                } actions: {
                    Button("Try Again") { Task { await reload() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Inbox")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showCompose = true } label: {
                    Label("Compose", systemImage: "square.and.pencil")
                }
            }
        }
        .task { await reload() }
        .sheet(isPresented: $showCompose) {
            ComposeEmailSheet { Task { await reload() } }
        }
    }

    private func reload() async {
        if emails.isEmpty { isLoading = true }
        errorMessage = nil
        do {
            let response = try await api.fetchEmails(limit: 50, offset: 0)
            emails = response.emails
            total = response.total
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }

    private func loadMore() async {
        guard !isLoadingMore, emails.count < total else { return }
        isLoadingMore = true
        do {
            let response = try await api.fetchEmails(limit: 50, offset: emails.count)
            emails += response.emails
            total = response.total
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoadingMore = false
    }
}

// MARK: - Email detail + reply

struct EmailDetailView: View {
    @EnvironmentObject var api: APIClient
    let email: EmailMessage
    @State private var thread: [EmailMessage] = []
    @State private var showReply = false

    private var threadOthers: [EmailMessage] {
        thread.filter { $0.id != email.id }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    EmailBadge(email: email)
                    Spacer()
                    if let received = email.receivedAt {
                        Text(received.prettyDateTime)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                LabeledContent("From") {
                    Text(email.fromAddr ?? "—")
                        .multilineTextAlignment(.trailing)
                }
                LabeledContent("To") {
                    Text(email.toAddr ?? "—")
                        .multilineTextAlignment(.trailing)
                }
                if let error = email.error, !error.isEmpty {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                if let body = email.body, !body.isEmpty {
                    Text(body)
                        .padding(.vertical, 2)
                }
            } header: {
                Text(email.subject ?? "(no subject)")
            }

            if let leadId = email.leadId {
                Section {
                    NavigationLink {
                        LeadDetailView(leadId: leadId)
                    } label: {
                        Label(email.leadName ?? "View lead", systemImage: "person.fill")
                    }
                }
            }

            if !threadOthers.isEmpty {
                Section("Thread") {
                    ForEach(threadOthers) { other in
                        NavigationLink {
                            EmailDetailView(email: other)
                        } label: {
                            EmailRow(email: other)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(email.leadName ?? email.counterpart)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if email.isInbound, !(email.fromAddr ?? "").isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reply") { showReply = true }
                }
            }
        }
        .sheet(isPresented: $showReply) {
            ReplySheet(email: email) { Task { await loadThread() } }
        }
        .task { await loadThread() }
    }

    private func loadThread() async {
        guard let leadId = email.leadId else { return }
        if let response = try? await api.fetchEmails(leadId: leadId, limit: 50) {
            thread = response.emails
        }
    }
}

struct ReplySheet: View {
    @EnvironmentObject var api: APIClient
    let email: EmailMessage
    let onSent: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var bodyText = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    private var subject: String {
        let subject = email.subject ?? ""
        if subject.lowercased().hasPrefix("re:") { return subject }
        return "Re: \(subject)"
    }

    /// The original, quoted, appended to the sent body (same as the web inbox).
    private var quotedOriginal: String {
        let lines = (email.body ?? "").split(separator: "\n", omittingEmptySubsequences: false)
        let quoted = lines.map { "> \($0)" }.joined(separator: "\n")
        let date = email.receivedAt?.prettyDateTime ?? ""
        let from = email.fromAddr ?? ""
        return "\n\nOn \(date), \(from) wrote:\n\(quoted)"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("To") {
                    Text(email.fromAddr ?? "")
                }
                Section("Subject") {
                    Text(subject)
                }
                Section("Message") {
                    TextField("Write your reply…", text: $bodyText, axis: .vertical)
                }
                Section("Quoted original") {
                    Text(quotedOriginal)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Reply")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Queue") { Task { await send() } }
                        .disabled(bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                }
            }
        }
    }

    private func send() async {
        isSending = true
        errorMessage = nil
        do {
            _ = try await api.queueEmail(
                leadId: email.leadId,
                to: email.fromAddr ?? "",
                subject: subject,
                body: bodyText + quotedOriginal,
                inReplyTo: email.gmailId)
            onSent()
            dismiss()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isSending = false
    }
}

// MARK: - Compose

struct ComposeEmailSheet: View {
    @EnvironmentObject var api: APIClient
    let onSent: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var to = ""
    @State private var subject = ""
    @State private var bodyText = ""
    @State private var leadId: Int?
    @State private var leadName: String?
    @State private var showLeadPicker = false
    @State private var isSending = false
    @State private var errorMessage: String?

    private var toLooksValid: Bool { to.contains("@") && to.contains(".") }

    private var canSend: Bool {
        toLooksValid
            && !subject.trimmingCharacters(in: .whitespaces).isEmpty
            && !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSending
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("To") {
                    TextField("Email address", text: $to)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if let leadName {
                        Label(leadName, systemImage: "person.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Button("Choose a lead…") { showLeadPicker = true }
                }
                Section("Subject") {
                    TextField("Subject", text: $subject)
                }
                Section {
                    TextField("Write your email…", text: $bodyText, axis: .vertical)
                } header: {
                    Text("Message")
                } footer: {
                    Text("Queued mail is sent only after you approve the send.")
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Email")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Queue") { Task { await send() } }
                        .disabled(!canSend)
                }
            }
            .sheet(isPresented: $showLeadPicker) {
                LeadPickerSheet { lead in
                    leadId = lead.id
                    leadName = lead.name
                    if let email = lead.email, !email.isEmpty { to = email }
                }
            }
        }
    }

    private func send() async {
        isSending = true
        errorMessage = nil
        do {
            _ = try await api.queueEmail(
                leadId: leadId,
                to: to.trimmingCharacters(in: .whitespaces),
                subject: subject.trimmingCharacters(in: .whitespaces),
                body: bodyText,
                inReplyTo: nil)
            onSent()
            dismiss()
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isSending = false
    }
}

struct LeadPickerSheet: View {
    @EnvironmentObject var api: APIClient
    let onPick: (Lead) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var leads: [Lead] = []

    var body: some View {
        NavigationStack {
            List(leads) { lead in
                Button {
                    onPick(lead)
                    dismiss()
                } label: {
                    LeadRow(lead: lead)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Choose a Lead")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search name, city, email")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task(id: searchText) {
                // Debounce typing; .task(id:) cancels the previous task on change.
                try? await Task.sleep(nanoseconds: 400_000_000)
                guard !Task.isCancelled else { return }
                await search()
            }
        }
    }

    private func search() async {
        if let response = try? await api.fetchLeads(
            search: searchText, industry: nil, status: nil, limit: 20, offset: 0) {
            leads = response.leads
        }
    }
}

// MARK: - Interest

struct InterestRow: View {
    let lead: Lead

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(lead.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                StatusBadge(status: lead.statusInfo)
            }
            Text([lead.contactPerson, lead.city].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let snippet = lead.replySnippet, !snippet.isEmpty {
                Text(snippet)
                    .font(.subheadline)
                    .lineLimit(2)
            }
            if let replied = lead.dateReplied {
                Text("Replied \(replied.prettyDate)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct InterestView: View {
    @EnvironmentObject var api: APIClient
    @State private var leads: [Lead] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if !leads.isEmpty {
                List {
                    ForEach(leads) { lead in
                        NavigationLink(value: lead) {
                            InterestRow(lead: lead)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable { await load() }
            } else if isLoading {
                ProgressView("Loading…")
            } else {
                ContentUnavailableView {
                    Label("No interest yet", systemImage: "star")
                } description: {
                    Text(errorMessage ?? "When someone replies to outreach, they'll show up here.")
                } actions: {
                    Button("Try Again") { Task { await load() } }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Interest")
        .navigationDestination(for: Lead.self) { lead in
            LeadDetailView(leadId: lead.id)
        }
        .task { await load() }
    }

    private func load() async {
        if leads.isEmpty { isLoading = true }
        errorMessage = nil
        do {
            let response = try await api.fetchInterestedLeads()
            leads = response.leads
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}
