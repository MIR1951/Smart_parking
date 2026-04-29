import SwiftUI

struct AddParkingReviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let parkingName: String
    let isSubmitting: Bool
    let onSubmit: (Int, String) async -> Void

    @State private var rating = 5
    @State private var comment = ""

    private let loc = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(parkingName)
                    .font(.headline)
                    .foregroundColor(AppTheme.Palette.textPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    Text(loc.str(.detailReviewRating))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { value in
                            Button {
                                rating = value
                            } label: {
                                Image(systemName: value <= rating ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundColor(AppTheme.Palette.warning)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(loc.str(.detailReviewComment))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    TextEditor(text: $comment)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(AppTheme.Palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                                .stroke(AppTheme.Palette.border, lineWidth: 1)
                        )
                }

                Spacer()

                Button {
                    Task {
                        await onSubmit(rating, comment)
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(loc.str(.detailSubmitReview))
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                    .frame(height: 48)
                    .foregroundColor(.white)
                    .background(AppTheme.Gradient.brand)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isSubmitting || comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(isSubmitting || comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
            }
            .padding()
            .navigationTitle(loc.str(.detailAddReview))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.str(.cancel)) { dismiss() }
                }
            }
        }
    }
}
