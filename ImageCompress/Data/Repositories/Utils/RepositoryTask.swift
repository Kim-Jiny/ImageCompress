//
//  RepositoryTask.swift
//  ImageCompress
//
//  Created by 김미진 on 10/11/24.
//

import Foundation

class RepositoryTask: Cancellable {
    var networkTask: NetworkCancellable?
    var isCancelled: Bool = false
    
    func cancel() {
        networkTask?.cancel()
        isCancelled = true
    }
}
