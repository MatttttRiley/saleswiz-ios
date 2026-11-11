import Foundation
import SwiftUI

// MARK: - Flexible decoding
// The PHP API returns SQLite rows as JSON: numbers as numbers, empty fields
// as null. These helpers tolerate either shape so a single odd value never
// breaks a whole screen.

extension KeyedDecodingContainer {
    func decodeFlexString(forKey key: Key) -> String? {
        if let s = try? decodeIfPresent(String.self, forKey: key) { return s }
        if let i = try? decodeIfPresent(Int.self, forKey: key) { return String(i) }
        if let d = try? decodeIfPresent(Double.self, forKey: key) { return String(d) }
        return nil
    }

    func decodeFlexInt(forKey key: Key) -> Int? {
        if let i = try? decodeIfPresent(Int.self, forKey: key) { return i }
        if let s = try? decodeIfPresent(String.self, forKey: key), let n = Int(s) { return n }
        if let d = try? decodeIfPresent(Double.self, forKey: key) { return Int(d) }
        return nil
    }

    func decodeFlexDouble(forKey key: Key) -> Double? {
        if let d = try? decodeIfPresent(Double.self, forKey: key) { return d }
        if let i = try? decodeIfPresent(Int.self, forKey: key) { return Double(i) }
        if let s = try? decodeIfPresent(String.self, forKey: key), let n = Double(s) { return n }
        return nil
    }

    func decodeFlexBool(forKey key: Key) -> Bool {
        if let b = try? decodeIfPresent(Bool.self, forKey: key) { return b }
        if let i = decodeFlexInt(forKey: key) { return i != 0 }
        return false
    }
}

// MARK: - Lead

struct HistoryEvent: Decodable, Identifiable, Hashable {
    let id: Int
    let leadId: Int?
    let kind: String
    let eventDate: String?
    let detail: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, kind, detail
        case leadId = "lead_id"
        case eventDate = "event_date"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeFlexInt(forKey: .id) ?? 0
        leadId = c.decodeFlexInt(forKey: .leadId)
        kind = c.decodeFlexString(forKey: .kind) ?? "note"
        eventDate = c.decodeFlexString(forKey: .eventDate)
        detail = c.decodeFlexString(forKey: .detail) ?? ""
        createdAt = c.decodeFlexString(forKey: .createdAt)
    }

    var icon: String {
        switch kind {
        case "email": return "envelope.fill"
        case "call": return "phone.fill"
        case "reply": return "arrowshape.turn.up.left.fill"
        case "status": return "arrow.triangle.2.circlepath"
        case "bounce": return "exclamationmark.triangle.fill"
        case "customer": return "star.fill"
        default: return "note.text"
        }
    }
}

struct Lead: Decodable, Identifiable, Hashable {
    let id: Int
    var name: String
    var industry: String?
    var city: String?
    var phone: String?
    var email: String?
    var contactPerson: String?
    var source: String?
    var status: String
    var dateEmailed: String?
    var dateCalled: String?
    var callOutcome: String?
    var dateReplied: String?
    var notes: String?
    var followUpDue: String?
    var doNotCall: Bool
    var doNotContact: Bool
    var bounceReason: String?
    var dateBounced: String?
    var servicesBought: String?
    var grokSetupStatus: String?
    var supportNotes: String?
    var billingRenewalDate: String?
    var inCallQueue: Bool
    var queuedBatch: Int?
    var replySnippet: String?
    var history: [HistoryEvent]?

    enum CodingKeys: String, CodingKey {
        case id, name, industry, city, phone, email, source, status, notes
        case contactPerson = "contact_person"
        case dateEmailed = "date_emailed"
        case dateCalled = "date_called"
        case callOutcome = "call_outcome"
        case dateReplied = "date_replied"
        case followUpDue = "follow_up_due"
        case doNotCall = "do_not_call"
        case doNotContact = "do_not_contact"
        case bounceReason = "bounce_reason"
        case dateBounced = "date_bounced"
        case servicesBought = "services_bought"
        case grokSetupStatus = "grok_setup_status"
        case supportNotes = "support_notes"
        case billingRenewalDate = "billing_renewal_date"
        case inCallQueue = "in_call_queue"
        case queuedBatch = "queued_batch"
        case replySnippet = "reply_snippet"
        case history
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeFlexInt(forKey: .id) ?? 0
        name = c.decodeFlexString(forKey: .name) ?? ""
        industry = c.decodeFlexString(forKey: .industry)
        city = c.decodeFlexString(forKey: .city)
        phone = c.decodeFlexString(forKey: .phone)
        email = c.decodeFlexString(forKey: .email)
        contactPerson = c.decodeFlexString(forKey: .contactPerson)
        source = c.decodeFlexString(forKey: .source)
        status = c.decodeFlexString(forKey: .status) ?? "not_contacted"
        dateEmailed = c.decodeFlexString(forKey: .dateEmailed)
        dateCalled = c.decodeFlexString(forKey: .dateCalled)
        callOutcome = c.decodeFlexString(forKey: .callOutcome)
        dateReplied = c.decodeFlexString(forKey: .dateReplied)
        notes = c.decodeFlexString(forKey: .notes)
        followUpDue = c.decodeFlexString(forKey: .followUpDue)
        doNotCall = c.decodeFlexBool(forKey: .doNotCall)
        doNotContact = c.decodeFlexBool(forKey: .doNotContact)
        bounceReason = c.decodeFlexString(forKey: .bounceReason)
        dateBounced = c.decodeFlexString(forKey: .dateBounced)
        servicesBought = c.decodeFlexString(forKey: .servicesBought)
        grokSetupStatus = c.decodeFlexString(forKey: .grokSetupStatus)
        supportNotes = c.decodeFlexString(forKey: .supportNotes)
        billingRenewalDate = c.decodeFlexString(forKey: .billingRenewalDate)
        inCallQueue = c.decodeFlexBool(forKey: .inCallQueue)
        queuedBatch = c.decodeFlexInt(forKey: .queuedBatch)
        replySnippet = c.decodeFlexString(forKey: .replySnippet)
        history = try? c.decodeIfPresent([HistoryEvent].self, forKey: .history)
    }

    var statusInfo: LeadStatus { LeadStatus(rawValue: status) ?? .notContacted }

    var displayCity: String {
        [city, industry].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// Digits-only phone number, with +1 for 10-digit US numbers, for tel: links.
    var telURL: URL? {
        guard let phone, !phone.isEmpty else { return nil }
        let digits = phone.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        let number = digits.count == 10 ? "+1" + digits : digits
        return URL(string: "tel:\(number)")
    }

    var mailURL: URL? {
        guard let email, !email.isEmpty else { return nil }
        return URL(string: "mailto:\(email)")
    }
}

// MARK: - Status + industry metadata

enum LeadStatus: String, CaseIterable {
    case notContacted = "not_contacted"
    case emailed
    case called
    case replied
    case interested
    case demoBooked = "demo_booked"
    case customer
    case lost
    case doNotContact = "do_not_contact"
    case bounced

    var label: String {
        switch self {
        case .notContacted: return "Not contacted"
        case .emailed: return "Emailed"
        case .called: return "Called"
        case .replied: return "Replied"
        case .interested: return "Interested"
        case .demoBooked: return "Demo booked"
        case .customer: return "Customer"
        case .lost: return "Lost"
        case .doNotContact: return "Do not contact"
        case .bounced: return "Bounced"
        }
    }

    var color: Color {
        switch self {
        case .notContacted: return .secondary
        case .emailed: return .blue
        case .called: return .orange
        case .replied: return .purple
        case .interested: return .teal
        case .demoBooked: return .indigo
        case .customer: return .green
        case .lost: return .red
        case .doNotContact: return .secondary
        case .bounced: return .red
        }
    }

    /// Statuses a lead can be moved to by hand.
    static var settable: [LeadStatus] {
        [.notContacted, .emailed, .called, .replied, .interested, .demoBooked, .customer, .lost, .doNotContact]
    }
}

enum Industry {
    static let all = ["plumber", "electrician", "real estate", "insurance", "used car"]

    static func icon(for industry: String?) -> String {
        switch industry {
        case "plumber": return "wrench.fill"
        case "electrician": return "bolt.fill"
        case "real estate": return "house.fill"
        case "insurance": return "shield.fill"
        case "used car": return "car.fill"
        default: return "briefcase.fill"
        }
    }

    static func label(for industry: String?) -> String {
        guard let industry, !industry.isEmpty else { return "Business" }
        return industry.prefix(1).uppercased() + industry.dropFirst()
    }
}

// MARK: - Dashboard

struct Money: Decodable {
    var setupCollected: Int?
    var mrr: Int?
    var setupFee: Int?
    var monthlyFee: Int?

    enum CodingKeys: String, CodingKey {
        case setupCollected = "setup_collected"
        case mrr
        case setupFee = "setup_fee"
        case monthlyFee = "monthly_fee"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        setupCollected = c.decodeFlexInt(forKey: .setupCollected)
        mrr = c.decodeFlexInt(forKey: .mrr)
        setupFee = c.decodeFlexInt(forKey: .setupFee)
        monthlyFee = c.decodeFlexInt(forKey: .monthlyFee)
    }
}

struct StageRate: Decodable {
    var lo: Double?
    var mid: Double?
    var hi: Double?
    var measured: Bool?
    var n: Int?

    enum CodingKeys: String, CodingKey { case lo, mid, hi, measured, n }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lo = c.decodeFlexDouble(forKey: .lo)
        mid = c.decodeFlexDouble(forKey: .mid)
        hi = c.decodeFlexDouble(forKey: .hi)
        measured = try? c.decodeIfPresent(Bool.self, forKey: .measured)
        n = c.decodeFlexInt(forKey: .n)
    }

    var percentText: String {
        guard let mid else { return "—" }
        return String(format: "%.1f%%", mid * 100)
    }
}

struct Eta: Decodable {
    var lowDays: Int?
    var midDays: Int?
    var highDays: Int?
    var emailDays: DayRange?
    var callDays: DayRange?
    var emailExpectedSales: Double?
    var callExpectedSales: Double?
    var stalled: Bool?
    var emailsPerDay: Int?
    var callsPerDay: Int?

    enum CodingKeys: String, CodingKey {
        case lowDays = "low_days"
        case midDays = "mid_days"
        case highDays = "high_days"
        case emailDays = "email_days"
        case callDays = "call_days"
        case emailExpectedSales = "email_expected_sales"
        case callExpectedSales = "call_expected_sales"
        case stalled
        case emailsPerDay = "emails_per_day"
        case callsPerDay = "calls_per_day"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lowDays = c.decodeFlexInt(forKey: .lowDays)
        midDays = c.decodeFlexInt(forKey: .midDays)
        highDays = c.decodeFlexInt(forKey: .highDays)
        emailDays = try? c.decodeIfPresent(DayRange.self, forKey: .emailDays)
        callDays = try? c.decodeIfPresent(DayRange.self, forKey: .callDays)
        emailExpectedSales = c.decodeFlexDouble(forKey: .emailExpectedSales)
        callExpectedSales = c.decodeFlexDouble(forKey: .callExpectedSales)
        stalled = try? c.decodeIfPresent(Bool.self, forKey: .stalled)
        emailsPerDay = c.decodeFlexInt(forKey: .emailsPerDay)
        callsPerDay = c.decodeFlexInt(forKey: .callsPerDay)
    }

    var rangeText: String {
        guard let lo = lowDays, let hi = highDays else { return "—" }
        return "\(lo)–\(hi) days"
    }

    var likelyText: String {
        guard let mid = midDays else { return "—" }
        return "most likely ~\(mid) days"
    }
}

struct DayRange: Decodable {
    var lo: Int?
    var mid: Int?
    var hi: Int?

    enum CodingKeys: String, CodingKey { case lo, mid, hi }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lo = c.decodeFlexInt(forKey: .lo)
        mid = c.decodeFlexInt(forKey: .mid)
        hi = c.decodeFlexInt(forKey: .hi)
    }

    var text: String {
        guard let lo, let hi else { return "—" }
        return "\(lo)–\(hi) days"
    }
}

struct ProgressInfo: Decodable {
    var percent: Int?
    var stage: String?
    var outreachFrac: Double?
    var outreachDone: Int?
    var pool: Int?

    enum CodingKeys: String, CodingKey {
        case percent, stage
        case outreachFrac = "outreach_frac"
        case outreachDone = "outreach_done"
        case pool
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        percent = c.decodeFlexInt(forKey: .percent)
        stage = c.decodeFlexString(forKey: .stage)
        outreachFrac = c.decodeFlexDouble(forKey: .outreachFrac)
        outreachDone = c.decodeFlexInt(forKey: .outreachDone)
        pool = c.decodeFlexInt(forKey: .pool)
    }
}

struct IndustryStats: Decodable {
    var total: Int?
    var delivered: Int?
    var replies: Int?
    var customers: Int?

    enum CodingKeys: String, CodingKey { case total, delivered, replies, customers }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        total = c.decodeFlexInt(forKey: .total)
        delivered = c.decodeFlexInt(forKey: .delivered)
        replies = c.decodeFlexInt(forKey: .replies)
        customers = c.decodeFlexInt(forKey: .customers)
    }
}

struct BatchLead: Decodable, Identifiable {
    let id: Int
    var name: String?
    var industry: String?
    var city: String?
    var email: String?

    enum CodingKeys: String, CodingKey { case id, name, industry, city, email }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeFlexInt(forKey: .id) ?? 0
        name = c.decodeFlexString(forKey: .name)
        industry = c.decodeFlexString(forKey: .industry)
        city = c.decodeFlexString(forKey: .city)
        email = c.decodeFlexString(forKey: .email)
    }
}

struct FollowupLead: Decodable, Identifiable {
    let id: Int
    var name: String?
    var industry: String?
    var city: String?
    var status: String?
    var followUpDue: String?

    enum CodingKeys: String, CodingKey {
        case id, name, industry, city, status
        case followUpDue = "follow_up_due"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeFlexInt(forKey: .id) ?? 0
        name = c.decodeFlexString(forKey: .name)
        industry = c.decodeFlexString(forKey: .industry)
        city = c.decodeFlexString(forKey: .city)
        status = c.decodeFlexString(forKey: .status)
        followUpDue = c.decodeFlexString(forKey: .followUpDue)
    }
}

struct CallQueueLead: Decodable, Identifiable {
    let id: Int
    var name: String?
    var industry: String?
    var city: String?
    var phone: String?

    enum CodingKeys: String, CodingKey { case id, name, industry, city, phone }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeFlexInt(forKey: .id) ?? 0
        name = c.decodeFlexString(forKey: .name)
        industry = c.decodeFlexString(forKey: .industry)
        city = c.decodeFlexString(forKey: .city)
        phone = c.decodeFlexString(forKey: .phone)
    }

    var telURL: URL? {
        guard let phone, !phone.isEmpty else { return nil }
        let digits = phone.filter { $0.isNumber }
        guard !digits.isEmpty else { return nil }
        let number = digits.count == 10 ? "+1" + digits : digits
        return URL(string: "tel:\(number)")
    }
}

struct QueuedBatchInfo: Decodable {
    var batch: Int?
    var count: Int?

    enum CodingKeys: String, CodingKey {
        case batch = "queued_batch"
        case count = "n"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        batch = c.decodeFlexInt(forKey: .batch)
        count = c.decodeFlexInt(forKey: .count)
    }
}

struct Dashboard: Decodable {
    var date: String?
    var total: Int?
    var sent: Int?
    var bounced: Int?
    var delivered: Int?
    var emailed: Int?
    var replies: Int?
    var interested: Int?
    var demos: Int?
    var customers: Int?
    var lost: Int?
    var doNotContact: Int?
    var notContacted: Int?
    var callsTotal: Int?
    var callsToday: Int?
    var callsLeftToday: Int?
    var remainingEmail: Int?
    var remainingPhone: Int?
    var inCallQueue: Int?
    var followupsDue: Int?
    var followupsToday: Int?
    var byIndustry: [String: IndustryStats]?
    var money: Money?
    var rates: [String: StageRate]?
    var eta: Eta?
    var progress: ProgressInfo?
    var nextBatch: [BatchLead]?
    var queuedBatch: QueuedBatchInfo?
    var followups: [FollowupLead]?
    var callQueue: [CallQueueLead]?

    enum CodingKeys: String, CodingKey {
        case date, total, sent, bounced, delivered, emailed, replies, interested
        case demos, customers, lost
        case doNotContact = "do_not_contact"
        case notContacted = "not_contacted"
        case callsTotal = "calls_total"
        case callsToday = "calls_today"
        case callsLeftToday = "calls_left_today"
        case remainingEmail = "remaining_email"
        case remainingPhone = "remaining_phone"
        case inCallQueue = "in_call_queue"
        case followupsDue = "followups_due"
        case followupsToday = "followups_today"
        case byIndustry = "by_industry"
        case money, rates, eta, progress
        case nextBatch = "next_batch"
        case queuedBatch = "queued_batch"
        case followups
        case callQueue = "call_queue"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = c.decodeFlexString(forKey: .date)
        total = c.decodeFlexInt(forKey: .total)
        sent = c.decodeFlexInt(forKey: .sent)
        bounced = c.decodeFlexInt(forKey: .bounced)
        delivered = c.decodeFlexInt(forKey: .delivered)
        emailed = c.decodeFlexInt(forKey: .emailed)
        replies = c.decodeFlexInt(forKey: .replies)
        interested = c.decodeFlexInt(forKey: .interested)
        demos = c.decodeFlexInt(forKey: .demos)
        customers = c.decodeFlexInt(forKey: .customers)
        lost = c.decodeFlexInt(forKey: .lost)
        doNotContact = c.decodeFlexInt(forKey: .doNotContact)
        notContacted = c.decodeFlexInt(forKey: .notContacted)
        callsTotal = c.decodeFlexInt(forKey: .callsTotal)
        callsToday = c.decodeFlexInt(forKey: .callsToday)
        callsLeftToday = c.decodeFlexInt(forKey: .callsLeftToday)
        remainingEmail = c.decodeFlexInt(forKey: .remainingEmail)
        remainingPhone = c.decodeFlexInt(forKey: .remainingPhone)
        inCallQueue = c.decodeFlexInt(forKey: .inCallQueue)
        followupsDue = c.decodeFlexInt(forKey: .followupsDue)
        followupsToday = c.decodeFlexInt(forKey: .followupsToday)
        byIndustry = try? c.decodeIfPresent([String: IndustryStats].self, forKey: .byIndustry)
        money = try? c.decodeIfPresent(Money.self, forKey: .money)
        rates = try? c.decodeIfPresent([String: StageRate].self, forKey: .rates)
        eta = try? c.decodeIfPresent(Eta.self, forKey: .eta)
        progress = try? c.decodeIfPresent(ProgressInfo.self, forKey: .progress)
        nextBatch = try? c.decodeIfPresent([BatchLead].self, forKey: .nextBatch)
        queuedBatch = try? c.decodeIfPresent(QueuedBatchInfo.self, forKey: .queuedBatch)
        followups = try? c.decodeIfPresent([FollowupLead].self, forKey: .followups)
        callQueue = try? c.decodeIfPresent([CallQueueLead].self, forKey: .callQueue)
    }
}

// MARK: - Lists

struct LeadsResponse: Decodable {
    var leads: [Lead]
    var total: Int
    var limit: Int?
    var offset: Int?
    var filters: FilterLists?

    enum CodingKeys: String, CodingKey { case leads, total, limit, offset, filters }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        leads = (try? c.decodeIfPresent([Lead].self, forKey: .leads)) ?? []
        total = c.decodeFlexInt(forKey: .total) ?? 0
        limit = c.decodeFlexInt(forKey: .limit)
        offset = c.decodeFlexInt(forKey: .offset)
        filters = try? c.decodeIfPresent(FilterLists.self, forKey: .filters)
    }
}

struct FilterLists: Decodable {
    var cities: [String]?
    var industries: [String]?
}

struct LeadResponse: Decodable {
    var lead: Lead
}

struct ActionsList: Decodable {
    var date: String?
    var followups: [FollowupLead]?
    var callQueue: [CallQueueLead]?
    var nextBatch: [BatchLead]?
    var callsLeftToday: Int?
    var callsToday: Int?

    enum CodingKeys: String, CodingKey {
        case date, followups
        case callQueue = "call_queue"
        case nextBatch = "next_batch"
        case callsLeftToday = "calls_left_today"
        case callsToday = "calls_today"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = c.decodeFlexString(forKey: .date)
        followups = try? c.decodeIfPresent([FollowupLead].self, forKey: .followups)
        callQueue = try? c.decodeIfPresent([CallQueueLead].self, forKey: .callQueue)
        nextBatch = try? c.decodeIfPresent([BatchLead].self, forKey: .nextBatch)
        callsLeftToday = c.decodeFlexInt(forKey: .callsLeftToday)
        callsToday = c.decodeFlexInt(forKey: .callsToday)
    }
}

struct QueueBatchResult: Decodable {
    var batch: Int?
    var queued: Int?

    enum CodingKeys: String, CodingKey { case batch, queued }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        batch = c.decodeFlexInt(forKey: .batch)
        queued = c.decodeFlexInt(forKey: .queued)
    }
}

// MARK: - Dates

extension String {
    /// "2026-11-10" -> Date, or nil.
    var asDayDate: Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "America/Denver")
        return f.date(from: self)
    }

    /// "Due today", "Due tomorrow", "Overdue 3 days", "Due Nov 12" — or nil.
    var dueText: String? {
        guard let date = asDayDate else { return nil }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let day = cal.startOfDay(for: date)
        let diff = cal.dateComponents([.day], from: today, to: day).day ?? 0
        switch diff {
        case 0: return "Due today"
        case 1: return "Due tomorrow"
        case ..<0: return "Overdue \(-diff) day\(-diff == 1 ? "" : "s")"
        default:
            let f = DateFormatter()
            f.dateFormat = "MMM d"
            return "Due \(f.string(from: date))"
        }
    }

    /// "Nov 10, 2026" for a yyyy-MM-dd string, or the string itself.
    var prettyDate: String {
        guard let date = asDayDate else { return self }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

extension Date {
    var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "America/Denver")
        return f.string(from: self)
    }
}

// MARK: - Email

/// One row of the CRM `emails` table (Gmail integration). Inbound rows are
/// synced in by the bridge; outbound rows are queued here and sent by the
/// bridge only after Matt approves each send.
struct EmailMessage: Decodable, Identifiable, Hashable {
    let id: Int
    var leadId: Int?
    var direction: String
    var fromAddr: String?
    var toAddr: String?
    var subject: String?
    var body: String?
    var gmailId: String?
    var receivedAt: String?
    var status: String?
    var error: String?
    var leadName: String?

    enum CodingKeys: String, CodingKey {
        case id, direction, subject, body, status, error
        case leadId = "lead_id"
        case fromAddr = "from_addr"
        case toAddr = "to_addr"
        case gmailId = "gmail_id"
        case receivedAt = "received_at"
        case leadName = "lead_name"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeFlexInt(forKey: .id) ?? 0
        leadId = c.decodeFlexInt(forKey: .leadId)
        direction = c.decodeFlexString(forKey: .direction) ?? "in"
        fromAddr = c.decodeFlexString(forKey: .fromAddr)
        toAddr = c.decodeFlexString(forKey: .toAddr)
        subject = c.decodeFlexString(forKey: .subject)
        body = c.decodeFlexString(forKey: .body)
        gmailId = c.decodeFlexString(forKey: .gmailId)
        receivedAt = c.decodeFlexString(forKey: .receivedAt)
        status = c.decodeFlexString(forKey: .status)
        error = c.decodeFlexString(forKey: .error)
        leadName = c.decodeFlexString(forKey: .leadName)
    }

    var isInbound: Bool { direction == "in" }

    /// The other side of the conversation: who sent it (inbound) or who it
    /// goes to (outbound).
    var counterpart: String {
        isInbound ? (fromAddr ?? "") : (toAddr ?? "")
    }

    var badgeLabel: String {
        if isInbound { return "In" }
        switch status {
        case "queued": return "Queued"
        case "sent": return "Sent"
        case "failed": return "Failed"
        default: return "Out"
        }
    }

    var badgeColor: Color {
        if isInbound { return .blue }
        switch status {
        case "queued": return .orange
        case "sent": return .green
        case "failed": return .red
        default: return .secondary
        }
    }
}

struct EmailsResponse: Decodable {
    var emails: [EmailMessage]
    var total: Int

    enum CodingKeys: String, CodingKey { case emails, total }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        emails = (try? c.decodeIfPresent([EmailMessage].self, forKey: .emails)) ?? []
        total = c.decodeFlexInt(forKey: .total) ?? 0
    }
}

struct InterestedLeadsResponse: Decodable {
    var leads: [Lead]
    var total: Int

    enum CodingKeys: String, CodingKey { case leads, total }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        leads = (try? c.decodeIfPresent([Lead].self, forKey: .leads)) ?? []
        total = c.decodeFlexInt(forKey: .total) ?? 0
    }
}

struct QueuedEmailResponse: Decodable {
    var email: EmailMessage
}

extension String {
    /// "2026-11-11 09:13:41" -> "Nov 11, 2026 at 9:13 AM", or the string itself.
    var prettyDateTime: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "America/Denver")
        guard let date = f.date(from: self) else { return self }
        let out = DateFormatter()
        out.dateStyle = .medium
        out.timeStyle = .short
        return out.string(from: date)
    }
}
