// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


import Foundation
import Photos

public protocol AssetLibraryDelegate: class {
    func assetLibraryDidChange(library: AssetLibrary)
}

public class AssetLibrary {
    public weak var delegate: AssetLibraryDelegate?
    private var fetchingAssets = false
    
    public var count: UInt {
        guard let fetch = self.fetch else {
            return 0
        }
        return UInt(fetch.count)
    }
    
    public enum AssetError: ErrorType {
        case OutOfRange, NotLoadedError
    }
    
    public func asset(atIndex index: UInt) throws -> PHAsset {
        guard let fetch = self.fetch else {
            throw AssetError.NotLoadedError
        }
        
        if index >= count {
            throw AssetError.OutOfRange
        }
        return fetch.objectAtIndex(Int(index)) as! PHAsset
    }
    
    public func refetchAssets() {
        guard !self.fetchingAssets else {
            return
        }
        
        self.fetchingAssets = true
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            self.fetch = PHAsset.fetchAssetsWithOptions(options)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.delegate?.assetLibraryDidChange(self)
                self.fetchingAssets = false
            })
        }
    }
    
    private var fetch: PHFetchResult?
    
    init() {
        self.refetchAssets()
    }
}
