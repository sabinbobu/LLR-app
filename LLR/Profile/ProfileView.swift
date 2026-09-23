import SwiftData
import SwiftUI

struct ProfileView: View {
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil }, sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]
    @State private var showingSettings = false

    private var summaries: [WorkoutSummary] { workouts.map(\.summary) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 28) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 96, height: 96)
                            .foregroundStyle(Color(.systemGray3))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Workouts").foregroundStyle(.secondary)
                            Text("\(workouts.count)").font(.title2)
                        }
                        Spacer()
                    }

                    WeeklyStatsCard(summaries: summaries)

                    Text("Dashboard").font(.title3).foregroundStyle(.secondary)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible())], spacing: 16) {
                        NavigationLink {
                            ExerciseListView()
                        } label: {
                            Label("Exercises", systemImage: "dumbbell")
                                .font(.title3)
                                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                                .padding(.horizontal, 18)
                        }
                        .buttonStyle(CardButtonStyle())
                        NavigationLink {
                            MuscleSplitView(summaries: summaries)
                        } label: {
                            Label("Muscle Split", systemImage: "figure.strengthtraining.traditional")
                                .font(.title3)
                                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                                .padding(.horizontal, 18)
                        }
                        .buttonStyle(CardButtonStyle())
                    }

                    Text("Workouts").font(.title3).foregroundStyle(.secondary)
                    if workouts.isEmpty {
                        EmptyStateCard(systemImage: "dumbbell", message: "No workouts yet")
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(workouts) { workout in
                                NavigationLink(value: workout) { WorkoutCard(workout: workout) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationDestination(for: Workout.self) { WorkoutDetailView(workout: $0) }
            .toolbar {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
    }
}
