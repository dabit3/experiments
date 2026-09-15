import SwiftUI

struct RecipeShelf: View {
  @EnvironmentObject private var library: LibraryStore
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var typeSize
  @State private var managing: Recipe?
  @State private var previews: [UUID: UIImage] = [:]
  var negative: Negative?
  var onApply: ((Recipe) -> Void)?

  var body: some View {
    VStack(spacing: 0) {
      SheetHeader(title: "Recipes") { dismiss() }
      ScrollView {
        VStack(alignment: .leading, spacing: 28) {
          Text("Your saved looks.").font(TypeStyle.title).padding(.top, 16)
          Text(
            onApply == nil
              ? "Looks and adjustments, ready to use again."
              : "Previewed on this photograph. Tap a look to apply it."
          )
          .font(TypeStyle.label).foregroundStyle(Palette.muted)
          if library.state.recipes.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
              Hairline()
              Text("Save your first look").font(TypeStyle.heading).padding(.top, 20)
              Text("Open a photograph, make your adjustments, then choose Recipes → Save recipe.")
                .font(TypeStyle.body).foregroundStyle(Palette.muted).lineSpacing(3)
            }
          }
          ForEach(library.state.recipes) { recipe in
            recipeRow(recipe)
              .task(id: recipe.settings) {
                guard
                  let example = negative ?? library.state.negatives.first(where: { $0.isSample }),
                  let data = try? library.data(for: example)
                else { return }
                let settings = recipe.settings
                previews[recipe.id] = await Task.detached(priority: .utility) {
                  try? ImageEngine().render(data, settings: settings, maxPixel: 400)
                }.value
              }
          }
          if !library.state.recipes.isEmpty {
            Text(
              negative == nil
                ? "Previews use The cove sample."
                : "Applying a recipe keeps this photo’s crop and rotation."
            )
            .font(TypeStyle.caption).foregroundStyle(Palette.muted)
          }
        }
        .padding(.horizontal, 24).padding(.bottom, 30)
      }
    }
    .foregroundStyle(Palette.silver).background(Palette.background)
    .presentationDragIndicator(.visible)
    .sheet(item: $managing) { recipe in
      RecipeNameSheet(
        title: "Edit recipe", initialName: recipe.name,
        onSave: { library.renameRecipe(recipe, name: $0) },
        onDelete: { library.deleteRecipe(recipe) })
    }
  }

  private func recipeRow(_ recipe: Recipe) -> some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack(alignment: .top, spacing: 16) {
        Button {
          if let onApply { onApply(recipe) } else { managing = recipe }
        } label: {
          HStack(alignment: .top, spacing: 16) {
            Group {
              if let preview = previews[recipe.id] {
                Image(uiImage: preview).resizable().scaledToFill()
              } else {
                Palette.panel
              }
            }
            .frame(width: 84, height: 112).clipped()
            .clipShape(RoundedRectangle(cornerRadius: 6)).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 10) {
              Text(recipe.name).font(TypeStyle.heading)
                .fixedSize(horizontal: false, vertical: true)
              if !typeSize.isAccessibilitySize { summary(recipe) }
              if onApply != nil {
                Text("Apply look").font(TypeStyle.label).underline()
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(onApply == nil ? "Edit \(recipe.name)" : "Apply \(recipe.name)")
        RoundControl(symbol: "ellipsis", label: "Manage \(recipe.name)") { managing = recipe }
      }
      if typeSize.isAccessibilitySize { summary(recipe) }
      Hairline()
    }
  }

  private func summary(_ recipe: Recipe) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(
        recipe.settings.film.title + " · " + String(format: "%+.2f EV", recipe.settings.exposure))
      Text(
        String(
          format: "%.2f contrast · %+.0f warmth", recipe.settings.contrast,
          recipe.settings.warmth * 100))
    }
    .font(TypeStyle.caption).foregroundStyle(Palette.muted)
    .fixedSize(horizontal: false, vertical: true)
  }
}
