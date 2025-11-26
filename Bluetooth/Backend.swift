import Foundation

class Backend {
    private let baseURL: URL
    private let session: URLSession
    
    init(host: String = "localhost", port: Int = 8000) {
        self.baseURL = URL(string: "http://\(host):\(port)")!
        self.session = URLSession.shared
    }
    
    // MARK: - GET
    func get(endpoint: String, completion: @escaping (Data?, Error?) -> Void) {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            completion(data, nil)
        }.resume()
    }
    
    // MARK: - PUT
    func put(endpoint: String, body: Data?, completion: @escaping (Data?, Error?) -> Void) {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            completion(data, nil)
        }.resume()
    }
}
