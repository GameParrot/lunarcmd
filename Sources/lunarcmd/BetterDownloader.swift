// Faster downloads on Linux


import Foundation
#if os(Linux)
import FoundationNetworking
#endif
extension String: Error {}

func dataDownload(url: URL) throws -> Data {
    var finished = false
    var download = Data.init()
    var errorr: Error?  = nil
    let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
        if error != nil {
            errorr = error
            finished = true
        }
        guard let data = data else { return }
        download = data
        finished = true
    }
    task.resume()
    
    while finished == false {
        usleep(50)
    }
    if errorr != nil {
        throw errorr!
    }
    return download
}
func stringDownload(url: URL) throws -> String {
    var finished = false
    var download: String? = ""
    var errorr: Error?  = nil
    let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
        if error != nil {
            errorr = error
            finished = true
        }
        
        guard let data = data else { return }
        download = String(data: data, encoding: .utf8)
        if download == nil {
            errorr = "Response is not a valid string"
            finished = true
        }
        finished = true
    }
    task.resume()
    
    while finished == false {
        usleep(50)
    }
    if errorr != nil {
        throw errorr!
    }
    return download!
}
