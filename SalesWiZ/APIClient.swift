import Foundation
import Security

// MARK: - Errors

enum APIError: Error, LocalizedError {
    case unauthorized
    case server(String)
    case network(Error)
    case decoding

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Your session expired. Please log in again."
        case .server(let message): return message
        case .network(let error): return error.localizedDescription
        case .decoding: return "The server sent something unexpected. Please try again."
        }
    }
}

// MARK: - Keychain (shared CRM password, stored on-device only)

enum Keychain {
    private static let service = "com.philbert.saleswiz"
    private static let account = "crm-password"

    static func savePassword(_ password: String) -> Bool {
        guard let data = password.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        return SecItemAdd(attrs as CFDictionary, nil) == errSecSuccess
    }

    static func readPassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let password = String(data: data, encoding: .utf8), !password.isEmpty else {
            return nil
        }
        return password
    }

    static func deletePassword() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - API client

/// Talks to the live SalesWiZ CRM at https://crm.129-146-5-140.sslip.io/.
/// Auth is the shared CRM password: POST it to login.php once, and the
/// session cookie authenticates every API call after that. The password is
/// kept in the Keychain so the app can re-log in silently when the server
/// session expires (401) — the user only types it once.
@MainActor
final class APIClient: ObservableObject {
    static let baseURL = URL(string: "https://crm.129-146-5-140.sslip.io")!

    @Published var loggedIn = false
    @Published var isAuthenticating = false
    @Published var authError: String?

    private let session = URLSession(configuration: .default)

    // MARK: Login / logout

    /// POST the password to login.php, then prove the session works with a
    /// dashboard call. On success the password is saved to the Keychain.
    func login(password: String) async -> Bool {
        isAuthenticating = true
        authError = nil
        defer { isAuthenticating = false }

        let posted = await postLogin(password: password)
        let ok = posted ? await verifySession() : false
        if ok {
            _ = Keychain.savePassword(password)
            loggedIn = true
            return true
        }
        authError = "Wrong password."
        return false
    }

    /// Try the saved password without asking the user. Used on launch and
    /// after a 401.
    func trySilentLogin() async -> Bool {
        guard let password = Keychain.readPassword() else { return false }
        let posted = await postLogin(password: password)
        let verified = posted ? await verifySession() : false
        if verified {
            loggedIn = true
            return true
        }
        return false
    }

    func logout() {
        Keychain.deletePassword()
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies where cookie.domain.contains("sslip.io") {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        loggedIn = false
    }

    private func postLogin(password: String) async -> Bool {
        var request = URLRequest(url: Self.baseURL.appendingPathComponent("login.php"))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: "password", value: password)]
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        // The login POST 302-redirects on success; what matters is the cookie
        // it sets, not the redirect target, so the result is ignored here and
        // verified with a dashboard call instead.
        _ = try? await session.data(for: request)
        return true
    }

    private func verifySession() async -> Bool {
        do {
            let dashboard: Dashboard = try await get(action: "dashboard", allowRetry: false)
            return dashboard.total != nil
        } catch {
            return false
        }
    }

    // MARK: Reads

    func fetchDashboard() async throws -> Dashboard {
        try await get(action: "dashboard")
    }

    func fetchLeads(search: String, industry: String?, status: String?,
                    limit: Int = 100, offset: Int = 0) async throws -> LeadsResponse {
        var params: [String: String] = ["limit": String(limit), "offset": String(offset)]
        if !search.isEmpty { params["q"] = search }
        if let industry, !industry.isEmpty { params["industry"] = industry }
        if let status, !status.isEmpty { params["status"] = status }
        return try await get(action: "leads", params: params)
    }

    func fetchLead(id: Int) async throws -> Lead {
        let response: LeadResponse = try await get(action: "lead", params: ["id": String(id)])
        return response.lead
    }

    func fetchActions() async throws -> ActionsList {
        try await get(action: "actions")
    }

    func fetchEmails(leadId: Int? = nil, limit: Int = 50, offset: Int = 0) async throws -> EmailsResponse {
        var params: [String: String] = ["limit": String(limit), "offset": String(offset)]
        if let leadId { params["lead_id"] = String(leadId) }
        return try await get(action: "list_emails", params: params)
    }

    func fetchInterestedLeads() async throws -> InterestedLeadsResponse {
        try await get(action: "interested_leads")
    }

    // MARK: Writes

    func logCall(leadId: Int, outcome: String, note: String?, followUpDue: String?) async throws -> Lead {
        var body: [String: String] = ["id": String(leadId), "outcome": outcome]
        if let note, !note.isEmpty { body["note"] = note }
        if let followUpDue { body["follow_up_due"] = followUpDue }
        let response: LeadResponse = try await post(action: "log_call", body: body)
        return response.lead
    }

    func logReply(leadId: Int, note: String?) async throws -> Lead {
        var body: [String: String] = ["id": String(leadId)]
        if let note, !note.isEmpty { body["note"] = note }
        let response: LeadResponse = try await post(action: "log_reply", body: body)
        return response.lead
    }

    func recordBounce(leadId: Int, reason: String?) async throws -> Lead {
        var body: [String: String] = ["id": String(leadId)]
        if let reason, !reason.isEmpty { body["reason"] = reason }
        let response: LeadResponse = try await post(action: "record_bounce", body: body)
        return response.lead
    }

    func updateLeadStatus(leadId: Int, status: String) async throws -> Lead {
        let body: [String: String] = ["id": String(leadId), "status": status]
        let response: LeadResponse = try await post(action: "update_lead", body: body)
        return response.lead
    }

    func addLead(name: String, industry: String?, city: String?, phone: String?,
                 email: String?, contactPerson: String?, notes: String?) async throws -> Lead {
        var body: [String: String] = ["name": name]
        if let industry, !industry.isEmpty { body["industry"] = industry }
        if let city, !city.isEmpty { body["city"] = city }
        if let phone, !phone.isEmpty { body["phone"] = phone }
        if let email, !email.isEmpty { body["email"] = email }
        if let contactPerson, !contactPerson.isEmpty { body["contact_person"] = contactPerson }
        if let notes, !notes.isEmpty { body["notes"] = notes }
        let response: LeadResponse = try await post(action: "add_lead", body: body)
        return response.lead
    }

    func queueBatch() async throws -> QueueBatchResult {
        try await post(action: "queue_batch", body: [:])
    }

    /// Queue an outbound email. It only sends after Matt approves the send
    /// (the bridge sends queued rows one approved row at a time). Returns
    /// the queued row. Pass `inReplyTo` (the Gmail id of the message being
    /// answered) to inherit that message's lead when `leadId` is nil.
    func queueEmail(leadId: Int?, to: String, subject: String, body: String,
                    inReplyTo: String?) async throws -> EmailMessage {
        var payload: [String: String] = ["to": to, "subject": subject, "body": body]
        if let leadId { payload["lead_id"] = String(leadId) }
        if let inReplyTo, !inReplyTo.isEmpty { payload["in_reply_to"] = inReplyTo }
        let response: QueuedEmailResponse = try await post(action: "queue_email", body: payload)
        return response.email
    }

    // MARK: Transport

    private struct Envelope: Decodable {
        var ok: Bool
        var error: String?
    }

    private func apiURL(action: String, params: [String: String] = [:]) -> URL {
        var components = URLComponents(url: Self.baseURL.appendingPathComponent("api.php"), resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "action", value: action)]
        items += params.map { URLQueryItem(name: $0.key, value: $0.value) }
        components.queryItems = items
        return components.url!
    }

    private func get<T: Decodable>(action: String, params: [String: String] = [:],
                                   allowRetry: Bool = true) async throws -> T {
        var request = URLRequest(url: apiURL(action: action, params: params))
        request.httpMethod = "GET"
        return try await send(request, allowRetry: allowRetry)
    }

    private func post<T: Decodable>(action: String, body: [String: String],
                                    allowRetry: Bool = true) async throws -> T {
        var request = URLRequest(url: apiURL(action: action))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        return try await send(request, allowRetry: allowRetry)
    }

    private func send<T: Decodable>(_ request: URLRequest, allowRetry: Bool) async throws -> T {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.network(error)
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.decoding }

        if http.statusCode == 401 {
            if allowRetry, await trySilentLogin() {
                return try await send(request, allowRetry: false)
            }
            loggedIn = false
            throw APIError.unauthorized
        }

        let envelope: Envelope
        do {
            envelope = try JSONDecoder().decode(Envelope.self, from: data)
        } catch {
            throw APIError.decoding
        }
        guard envelope.ok else {
            throw APIError.server(envelope.error ?? "The server declined the request.")
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }
}
