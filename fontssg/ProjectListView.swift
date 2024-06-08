//
//  ProjectView.swift
//  fontssg
//
//  Created by 안재원 on 5/21/24.
//

import Foundation
import SwiftData
import SwiftUI

struct ProjectListView: View {
    @Query private var projects: [Project]
    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingAddProject = false
    @State private var isPresentingDuplicateNameAlert = false
    @State private var projectName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(projects) { project in
                    NavigationLink(project.name, value: project)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(projects[index])
                    }
                }
            }.toolbar {
                EditButton()
            }
            .navigationTitle("Projects")
            .navigationBarItems(
                trailing: Button(
                    action: {
                        isPresentingAddProject = true
                    }, label: {
                        Image(systemName: "plus")
                    }
                )
                .alert("New Project", isPresented: $isPresentingAddProject, actions: {
                    TextField("Project Name", text: $projectName)
                    Button("Confirm", action: {
                        if projects.contains(where: { $0.name == projectName }) {
                            isPresentingDuplicateNameAlert = true
                            return
                        }
                        modelContext.insert(Project(name: projectName))
                        projectName = ""
                        isPresentingAddProject = false
                    })
                    Button("Cancel", role: .cancel) {
                        isPresentingAddProject = false
                    }
                })
                .alert("Duplicate Name", isPresented: $isPresentingDuplicateNameAlert, actions: {
                    Button("OK", role: .cancel) {
                        projectName = ""
                        isPresentingDuplicateNameAlert = false
                    }
                }, message: {
                    Text("The project name is already in use.")
                })
            )
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(project: project)
            }
        }
    }
}

#Preview {
    let schema = Schema([Project.self])
    let modelConfiguration = ModelConfiguration(
        isStoredInMemoryOnly: true
    )
    let container = try! ModelContainer(
        for: schema,
        configurations: modelConfiguration
    )
    return ProjectListView()
        .modelContainer(for: Project.self, inMemory: true)
}
