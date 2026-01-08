import SwiftUI

struct WinDetailView: View {
    @Binding var win: Win
    var onSave: () -> Void
    
    
    
    var body: some View {
        Form {
            Section(header: Text("Basic Info")) {
                TextField("Win Title", text: $win.title)
                DatePicker("Date Achieved", selection: $win.date, displayedComponents: .date)
                
                Picker("Category", selection: $win.type) {
                    ForEach(ObjectiveType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
            
            Section(header: Text("Win Reflection")) {
                VStack(alignment: .leading) {
                    Text("What is your win?")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Big win...", text: $win.title, axis: .vertical)
                }
                
                VStack(alignment: .leading) {
                    Text("What did you do?")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Actions taken...", text: $win.whatDidYouDo, axis: .vertical)
                }
                
                VStack(alignment: .leading) {
                    Text("What helped and was not in your control?")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("External factors...", text: $win.uncontrollableFactors, axis: .vertical)
                }
                
                VStack(alignment: .leading) {
                    Text("What did you learn by accomplishing it?")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Lessons learned...", text: $win.learnAccomplishing, axis: .vertical)
                }
                
                VStack(alignment: .leading) {
                    Text("What did you learn about yourself?")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Self discovery...", text: $win.learnAboutSelf, axis: .vertical)
                }
                
                VStack(alignment: .leading) {
                    Text("Where else can you use these lessons?")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Application...", text: $win.useLessonsElsewhere, axis: .vertical)
                }
                
                VStack(alignment: .leading) {
                    Text("How does it help with your bigger objectives?")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Alignment...", text: $win.helpBiggerObjectives, axis: .vertical)
                }
                
                VStack(alignment: .leading) {
                    Text("How will you celebrate?")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Celebration...", text: $win.celebration, axis: .vertical)
                }
                
                VStack(alignment: .leading) {
                    Text("Other notes")
                        .font(.caption)
                        .foregroundColor(.gray)
                    TextField("Notes...", text: $win.notes, axis: .vertical)
                }
            }
        }
        .navigationTitle("Win Details")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            onSave()
        }
    }
}
