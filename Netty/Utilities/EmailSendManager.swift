//
//  EmailSendManager.swift
//  Netty
//
//  Created by Danny on 18/07/2022.
//

import Foundation
import Combine

actor EmailSendManager {
    
    static let instance = EmailSendManager()
    private init() {}
    
    /// Sends e-mail to e-mail address from stated e-mail address with stated subject and text
    func sendEmail(to: String, from: String = "no-reply@nettysupport.com", subject: String, type: String = "text/plain", text: String) async throws -> Data {
        guard let url = URL(string: "https://rapidprod-sendgrid-v1.p.rapidapi.com/mail/send") else { throw EmailSendingError.url }
        
        // E-mail forming
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
        
        guard let postData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else { throw EmailSendingError.serialization }
        
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

