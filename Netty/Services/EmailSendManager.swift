//
//  EmailSendManager.swift
//  Netty
//
//  Created by Danny on 18/07/2022.
//

import Foundation
import Combine

enum EmailSendError: Error {
    case serialization
    case url
}

extension EmailSendError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .serialization:
            return NSLocalizedString("Error while serialization data", comment: "Error while sending e-mail")
        case .url:
            return NSLocalizedString("Error while getting URL", comment: "URL getting error")
        }
    }
}


actor EmailSendManager {
    
    static let instance = EmailSendManager()
    private init() {}
    

    func sendEmail(to: String, from: String = "no-reply@nettysupport.com", subject: String, type: String = "text/plain", text: String) async throws -> Data {
        guard let url = URL(string: "https://rapidprod-sendgrid-v1.p.rapidapi.com/mail/send") else { throw EmailSendError.url }
        
        let headers = [
            "content-type": "application/json",
            "X-RapidAPI-Key": "f651d68838msh1df01afcec3c473p1cd121jsn33db27102e12",
            "X-RapidAPI-Host": "rapidprod-sendgrid-v1.p.rapidapi.com"
        ]
        let parameters = [
            "personalizations": [
                [
                    "to": [["email": to]],
                    "subject": subject
                ]
            ],
            "from": ["email": from],
            "content": [
                [
                    "type": type,
                    "value": text
                ]
            ]
        ] as [String : Any]
        
        guard let postData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else { throw EmailSendError.serialization }
        
        var request: URLRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData as Data
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode < 300 {
            return data
        } else { throw URLError(.badServerResponse) }
    }
}

