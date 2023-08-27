//
//  SheetView.swift
//  ChainXS
//
//  Created by Laurenz Zielinski
//

import SwiftUI
struct SheetView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Button("Press to dismiss") {
            dismiss()
        }
        .font(.title)
        .padding()
        .background(.black)
    }
}