//
//  SettingsView.swift
//  tensr
//
//  Created by azim on 8/14/19.
//  Copyright © 2019 azim. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @State var params: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                
                HStack {
                    Text("Params: ")
                        .font(.headline)
                    
                    TextField("params", text: $params)
                        .font(.subheadline)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                }
                Button(action: (self.setParams), label: {
                    Text("Set Params")
                })
            }
            
            
        }
        .navigationBarTitle(Text("Settings"), displayMode: .large)
        
    }
    
    func setParams() {
        print("Use \(self.params) instead!")
    }
    
}


#if DEBUG
struct SettingsView_Preview: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
#endif
