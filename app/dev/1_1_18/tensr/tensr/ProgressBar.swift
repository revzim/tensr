//
//  ProgressBar.swift
//  tensr
//
//  Created by azim on 8/13/19.
//  Copyright © 2019 azim. All rights reserved.
//

import SwiftUI

struct ProgressBar : View {
    @Binding<Double> var value: Double

    var body: some View {
        ZStack(alignment: Alignment.leading) {
            Rectangle()
                .opacity(0.3)
            
            Rectangle()
                // TRIVIAL HACK FOR MAXWIDTH MULTIPLY BY VALUE TO GET BIG SCREEN WIDTH
                .frame(minWidth: 0, maxWidth: CGFloat(value) * 4, alignment: .leading)
                .opacity(0.6)
//                .animation(.fluidSpring())
                .animation(.spring(response: 1.0, dampingFraction: 1.0, blendDuration: 1.0))
        }
        .frame(height: 20)
        .cornerRadius(2)
    }
}
