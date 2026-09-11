import SwiftUI

struct RecipeShelf: View {
  @EnvironmentObject private var library: LibraryStore
  @Environment(\.dismiss) private var dismiss
  @State private var renaming: Recipe?
  @State private var newName = ""
  var onApply: ((Recipe) -> Void)?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Eyebrow(text: "Your signature looks").padding(.top, 18)
          Text("Good light,\nremembered.")
            .font(.system(size: 36, design: .serif)).foregroundStyle(Palette.silver)
          Text(
            onApply == nil
              ? "A collection of the looks you’ve made."
              : "Choose a recipe to develop this photograph."
          )
          .font(.subheadline).foregroundStyle(Palette.muted)
          Hairline()
          if library.state.recipes.isEmpty {
            VStack(alignment: .leading, spacing: 15) {
              Image(systemName: "bookmark").font(.title).foregroundStyle(Palette.amber)
              Text("Your first recipe starts\nwith a photograph.")
                .font(.system(.title2, design: .serif)).foregroundStyle(Palette.silver)
              Text(
                "Open a negative, find a look you love, then tap Save recipe. We’ll keep the look and adjustments here."
              )
              .font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4)
            }
            .padding(.vertical, 25)
          }
          ForEach(library.state.recipes) { recipe in
            recipeRow(recipe)
          }
        }
        .padding(.horizontal, 26).padding(.bottom, 30)
      }
      .background(Palette.background)
      .navigationTitle("Recipes").navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
      .alert(
        "Rename recipe",
        isPresented: Binding(
          get: { renaming != nil }, set: { if !$0 { renaming = nil } })
      ) {
        TextField("Recipe name", text: $newName)
        Button("Cancel", role: .cancel) { renaming = nil }
        Button("Save") {
          if let renaming { library.renameRecipe(renaming, name: newName) }
          renaming = nil
        }
        .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
    }
  }

  private func recipeRow(_ recipe: Recipe) -> some View {
    VStack(alignment: .leading, spacing: 13) {
      HStack(alignment: .top, spacing: 14) {
        Text(recipe.settings.film.code)
          .font(.system(size: 34, weight: .ultraLight, design: .serif))
          .foregroundStyle(Palette.amber)
        VStack(alignment: .leading, spacing: 6) {
          Text(recipe.name).font(.system(.title2, design: .serif)).foregroundStyle(Palette.silver)
          Text(
            recipe.settings.film.title + " / "
              + String(format: "%+.2f EV", recipe.settings.exposure)
          )
          .font(.system(.caption, design: .monospaced)).foregroundStyle(Palette.muted)
        }
        Spacer(minLength: 0)
        Menu {
          Button("Rename", systemImage: "pencil") {
            newName = recipe.name
            renaming = recipe
          }
          Button("Delete recipe", systemImage: "trash", role: .destructive) {
            library.deleteRecipe(recipe)
          }
        } label: {
          Image(systemName: "ellipsis").frame(width: 44, height: 44).foregroundStyle(Palette.muted)
        }
        .accessibilityLabel("Manage \(recipe.name)")
      }
      if let onApply {
        Button {
          onApply(recipe)
        } label: {
          HStack {
            Text("Apply recipe")
            Spacer()
            Image(systemName: "arrow.right")
          }
          .font(.subheadline).foregroundStyle(Palette.amber).frame(minHeight: 44)
        }
        .accessibilityLabel("Apply \(recipe.name)")
      }
      Hairline()
    }
  }
}
