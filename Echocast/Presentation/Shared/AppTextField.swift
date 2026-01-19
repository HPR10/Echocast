//
//  AppTextField.swift
//  Echocast
//
//  Created by Hugo Pinheiro on 19/01/26.
//

import SwiftUI

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var leadingSystemImage: String?
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var textInputAutocapitalization: TextInputAutocapitalization? = nil
    var autocorrectionDisabled: Bool = false
    var submitLabel: SubmitLabel = .return
    var hasError: Bool = false
    var focus: FocusState<Bool>.Binding?

    var body: some View {
        HStack(spacing: 12) {
            if let leadingSystemImage {
                Image(systemName: leadingSystemImage)
                    .foregroundStyle(.secondary)
            }

            configuredTextField
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }

    private var borderColor: Color {
        hasError ? .red : Color.secondary.opacity(0.35)
    }

    @ViewBuilder
    private var configuredTextField: some View {
        if let focus {
            baseTextField
                .focused(focus)
        } else {
            baseTextField
        }
    }

    private var baseTextField: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .textInputAutocapitalization(textInputAutocapitalization)
            .autocorrectionDisabled(autocorrectionDisabled)
            .textContentType(textContentType)
            .submitLabel(submitLabel)
    }
}
