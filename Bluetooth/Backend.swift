import Foundation

class Backend {
    static let shared = Backend()
    
    private let session: URLSession
    private var baseURL: URL
    
    // MARK: - Initialization
    private init(host: String = "localhost", port: Int = 8000) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        self.baseURL = URL(string: "http://\(host):\(port)")!
    }
    
    // MARK: - Configuration
    /// Update the server address
    func setServerAddress(host: String, port: Int) {
        self.baseURL = URL(string: "http://\(host):\(port)")!
    }
    
    // MARK: - GET Request
    /// Send a GET request to the specified endpoint
    /// - Parameters:
    ///   - endpoint: The API endpoint (e.g., "/api/status")
    ///   - completion: Callback with optional data and error
    func get(endpoint: String, completion: @escaping (Data?, Error?) -> Void) {
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        executeRequest(request, completion: completion)
    }
    
    /// Send a GET request and decode the response
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - responseType: The type to decode the response to
    ///   - completion: Callback with decoded object or error
    func get<T: Decodable>(
        endpoint: String,
        responseType: T.Type,
        completion: @escaping (T?, Error?) -> Void
    ) {
        get(endpoint: endpoint) { data, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.lastError = error.localizedDescription
                    completion(nil, error)
                }
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "Backend", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                DispatchQueue.main.async {
                    self.lastError = "No data received"
                    completion(nil, error)
                }
                return
            }
            
            do {
                let decodedObject = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async {
                    self.lastError = nil
                    completion(decodedObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    self.lastError = "Decoding error: \(error.localizedDescription)"
                    completion(nil, error)
                }
            }
        }
    }
    
    // MARK: - PUT Request
    /// Send a PUT request with optional body
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - body: Optional data to send
    ///   - completion: Callback with response data and error
    func put(endpoint: String, body: Data? = nil, completion: @escaping (Data?, Error?) -> Void) {
        let url = baseURL.appendingPathComponent(endpoint)
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        executeRequest(request, completion: completion)
    }
    
    /// Send a PUT request with an encodable object
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - body: Object to encode and send
    ///   - completion: Callback with response data and error
    func put<T: Encodable>(
        endpoint: String,
        body: T,
        completion: @escaping (Data?, Error?) -> Void
    ) {
        do {
            let jsonData = try JSONEncoder().encode(body)
            put(endpoint: endpoint, body: jsonData, completion: completion)
        } catch {
            DispatchQueue.main.async {
                self.lastError = "Encoding error: \(error.localizedDescription)"
                completion(nil, error)
            }
        }
    }
    
    /// Send a PUT request with an encodable body and decode the response
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - body: Object to encode and send
    ///   - responseType: The type to decode the response to
    ///   - completion: Callback with decoded object or error
    func put<T: Encodable, R: Decodable>(
        endpoint: String,
        body: T,
        responseType: R.Type,
        completion: @escaping (R?, Error?) -> Void
    ) {
        put(endpoint: endpoint, body: body) { data, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.lastError = error.localizedDescription
                    completion(nil, error)
                }
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "Backend", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                DispatchQueue.main.async {
                    self.lastError = "No data received"
                    completion(nil, error)
                }
                return
            }
            
            do {
                let decodedObject = try JSONDecoder().decode(R.self, from: data)
                DispatchQueue.main.async {
                    self.lastError = nil
                    completion(decodedObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    self.lastError = "Decoding error: \(error.localizedDescription)"
                    completion(nil, error)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    /// Check server connectivity
    /// - Parameter completion: Callback with connection status
    func checkConnectivity(completion: @escaping (Bool) -> Void) {
        get(endpoint: "/health") { data, error in
            DispatchQueue.main.async {
                self.isConnected = error == nil
                completion(self.isConnected)
            }
        }
    }
    
    /// Private method to execute URLRequest
    private func executeRequest(_ request: URLRequest, completion: @escaping (Data?, Error?) -> Void) {
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.lastError = error.localizedDescription
                    completion(nil, error)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    let error = NSError(domain: "Backend", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                    self.lastError = "Invalid response"
                    completion(nil, error)
                    return
                }
                
                guard (200...299).contains(httpResponse.statusCode) else {
                    let error = NSError(domain: "Backend", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
                    self.lastError = "HTTP \(httpResponse.statusCode)"
                    completion(nil, error)
                    return
                }
                
                self.lastError = nil
                completion(data, nil)
            }
        }.resume()
    }
}
