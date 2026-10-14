import SwiftData
import SwiftUI

struct ProfileView: View {
    @Query(filter: #Predicate<Workout> { $0.endedAt != nil && $0.sectionRaw != "kineto" }, sort: \Workout.startedAt, order: .reverse)
    private var workouts: [Workout]
    @AppStorage(StorageKey.effortScale) private var effortScale: EffortScale = .off
    @State private var showingSettings = false
    @State private var avatar = AvatarStore.load()

    private var summaries: [WorkoutSummary] { workouts.map(\.summary) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    NavigationLink {
                        ProfileDetailsView(avatar: $avatar)
                    } label: {
                        ProfileHeaderCard(starts: workouts.map(\.startedAt), avatar: avatar)
                    }
                    .buttonStyle(HeroCardButtonStyle())

                    RecoveryCard(workouts: workouts)
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
                        NavigationLink {
                            BodyView()
                        } label: {
                            Label("Body", systemImage: "figure.stand")
                                .font(.title3)
                                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                                .padding(.horizontal, 18)
                        }
                        .buttonStyle(CardButtonStyle())
                        NavigationLink {
                            WeeklyVolumeView(entries: workouts.flatMap(\.recoveryEntries))
                        } label: {
                            Label("Weekly Volume", systemImage: "chart.bar.xaxis")
                                .font(.title3)
                                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                                .padding(.horizontal, 18)
                        }
                        .buttonStyle(CardButtonStyle())
                        NavigationLink {
                            StructuralBalanceView(workouts: workouts)
                        } label: {
                            Label("Balance", systemImage: "scalemass")
                                .font(.title3)
                                .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                                .padding(.horizontal, 18)
                        }
                        .buttonStyle(CardButtonStyle())
                        // Only once sets are being rated: an empty effort screen is noise for everyone else.
                        if effortScale != .off {
                            NavigationLink {
                                EffortStatsView(samples: workouts.flatMap(\.recoveryEntries).map {
                                    EffortStats.Sample(date: $0.completedAt, rir: $0.rir)
                                })
                            } label: {
                                Label("Effort", systemImage: "flame")
                                    .font(.title3)
                                    .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
                                    .padding(.horizontal, 18)
                            }
                            .buttonStyle(CardButtonStyle())
                        }
                    }

                    Text("Workouts").font(.title3).foregroundStyle(.secondary)
                    if workouts.isEmpty {
                        EmptyStateCard(systemImage: "dumbbell", message: "No workouts yet")
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(workouts) { workout in
                                NavigationLink(value: workout) { HistoryCard(workout: workout) }
                                    .buttonStyle(.plain)
                                    .workoutActions(workout)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationDestination(for: Workout.self) { HistoryDestination(workout: $0) }
            .toolbar {
                NavigationLink {
                    WorkoutCalendarView(workouts: workouts)
                } label: {
                    Image(systemName: "calendar")
                }
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
