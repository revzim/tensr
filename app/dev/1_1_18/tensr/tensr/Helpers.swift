//
//  Helpers.swift
//  tensr
//
//  Created by azim on 8/13/19.
//  Copyright © 2019 azim. All rights reserved.
//

import Foundation

func isStartVowel (str: String) -> Bool {
    let vowels:[Character] = ["a", "e", "i", "o", "u"]
    
    for vowel in vowels {
        if str[str.startIndex] == vowel {
            return true
        }
    }
    
    return false
}
