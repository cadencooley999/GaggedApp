//
//  ReportSheet.swift
//  GaggedApp
//
//  Created by Caden Cooley on 2/26/26.
//

import SwiftUI

struct ReportSheetView: View {
    // Controls presentation
    @Binding var showReportSheet: Bool
    
    @Binding var preReportInfo: preReportModel?

    // Optional callback with the selected reason
    var onDone: ((String) -> Void)? = nil

    // Reasons list (3 options)
    private let reasons: [String] = [
        "Harassment or Hate",
        "Inappropriate Content",
        "Spam or Scam",
        "Another Reason"
    ]
    
    let reasonToType: [String: ReportReason] = [
        "Harassment or Hate": .hate,
        "Inappropriate Content": .inapropriate,
        "Spam or Scam": .spam,
        "Another Reason": .other
    ]

    @State private var selectedReason: String? = nil
    @State var reportAdded: Bool = false

    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Text("Reason For Reporting")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.theme.gray)
                    .padding(12)
                // Options container (not scrollable)
                VStack(spacing: 0) {
                    ForEach(Array(reasons.enumerated()), id: \.offset) { index, reason in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedReason == reason {
                                    selectedReason = nil
                                }
                                else {
                                    selectedReason = reason
                                }
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Text(reason)
                                    .font(.body)
                                    .foregroundStyle(Color.theme.accent)

                                Spacer()

                                if selectedReason == reason {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.theme.darkRed)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(Color.theme.lightGray)
                                }
                            }
                            .padding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < reasons.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Rectangle().fill(.ultraThinMaterial))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.theme.lightGray.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Bottom action bar (not scrollable)
                HStack {
                    Spacer()
                    Button {
                        guard let reason = selectedReason else { return }
                        onDone?(reason)
                        Task {
                            try await addReport()
                        }
                    } label: {
                        if reportAdded {
                            Image(systemName: "checkmark")
                                .font(.headline)
                                .foregroundStyle(Color.theme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 18)
                                .frame(height: 44)
                                .glassEffect(.regular.tint(Color.theme.darkRed), in: .rect(cornerRadius: 22))
                                .shadow(color: Color.black.opacity(0.18), radius: 12, y: 6)
                        } else {
                            Text("Done")
                                .font(.headline)
                                .foregroundStyle(Color.theme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 18)
                                .frame(height: 44)
                                .glassEffect(.regular.tint(Color.theme.darkRed), in: .rect(cornerRadius: 22))
                                .contentShape(Rectangle())
                                .shadow(color: Color.black.opacity(0.18), radius: 12, y: 6)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedReason == nil)
                    .opacity(selectedReason == nil ? 0.5 : 1)
                    Spacer()
                }
                .padding(.bottom)
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Header (Styled like SettingsView)
    private var header: some View {
        HStack {
            Image(systemName: "xmark")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showReportSheet = false
                    }
                }

            Spacer()

            Text("Report")
                .font(.headline)

            Spacer()

            // Placeholder for symmetry
            Image(systemName: "xmark")
                .font(.title3)
                .padding(8)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .glassEffect(.regular.interactive())
                .opacity(0)
        }
        .padding(.horizontal)
        .padding(.bottom)
        .frame(height: 55)
    }
    
    func addReport() async throws {
        print("in")
        print(preReportInfo)
        if let info = preReportInfo {
            print("found")
            print(preReportInfo?.contentType.rawValue, "Content type")
            let reason: ReportReason = reasonToType[selectedReason ?? "Another Reason"] ?? .other
            let newReport = ReportModel(id: "", contentType: info.contentType, contentId: info.contentId, contentAuthorId: info.contentAuthorId, reportAuthorId: info.reportAuthorId, reason: reason, status: .pending, createdAt: nil)
            try await ReportManager.shared.addReport(report: newReport)
            withAnimation(.easeInOut(duration: 0.3)) {
                reportAdded = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showReportSheet = false
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                reportAdded = false
            }
        }
    }
}


