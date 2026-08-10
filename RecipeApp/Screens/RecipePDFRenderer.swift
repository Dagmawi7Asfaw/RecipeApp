import PDFKit
import SwiftUI
import UIKit

class RecipePDFRenderer {
    static let shared = RecipePDFRenderer()
    
    func generatePDF(for recipe: RecipeModel, servingSize: Int) -> Data {
        let pageWidth: CGFloat = 612 // Standard US Letter width
        let pageHeight: CGFloat = 792 // Standard US Letter height
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            var currentY: CGFloat = 40
            let margin: CGFloat = 40
            let contentWidth = pageWidth - (margin * 2)
            
            // 1. Header: Recipe Title
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: UIColor.label
            ]
            let titleString = NSAttributedString(string: recipe.name, attributes: titleAttributes)
            titleString.draw(in: CGRect(x: margin, y: currentY, width: contentWidth, height: 32))
            currentY += 36
            
            // 2. Subtitle: Category, Timing, Servings
            let metaFont = UIFont.systemFont(ofSize: 12)
            let metaAttributes: [NSAttributedString.Key: Any] = [
                .font: metaFont,
                .foregroundColor: UIColor.secondaryLabel
            ]
            var metaText = "Category: \(recipe.viewCategory)  |  Prep: \(recipe.prepTimeMinutes) mins  |  Cook: \(recipe.minutesToCook) mins  |  Servings: \(servingSize)"
            if let loc = recipe.locationName {
                metaText += "  |  Origin: \(loc)"
            }
            let metaString = NSAttributedString(string: metaText, attributes: metaAttributes)
            metaString.draw(in: CGRect(x: margin, y: currentY, width: contentWidth, height: 20))
            currentY += 28
            
            // 3. Image (if available)
            if let image = recipe.viewImage {
                let imgHeight: CGFloat = 160
                image.draw(in: CGRect(x: margin, y: currentY, width: contentWidth, height: imgHeight))
                currentY += imgHeight + 20
            }
            
            // 4. Two-Column Layout: Left = Ingredients, Right = Instructions
            let colWidth = (contentWidth - 20) / 2
            
            // Left: Ingredients
            var ingY = currentY
            let secHeaderFont = UIFont.boldSystemFont(ofSize: 15)
            let ingHeader = NSAttributedString(string: "INGREDIENTS", attributes: [.font: secHeaderFont, .foregroundColor: UIColor.label])
            ingHeader.draw(in: CGRect(x: margin, y: ingY, width: colWidth, height: 20))
            ingY += 24
            
            let bodyFont = UIFont.systemFont(ofSize: 11)
            for ing in recipe.viewSortedIngredients {
                let text = "• \(ing.scaledIngredient(baseServing: recipe.servingSize, targetServing: servingSize))"
                let ingStr = NSAttributedString(string: text, attributes: [.font: bodyFont, .foregroundColor: UIColor.label])
                ingStr.draw(in: CGRect(x: margin, y: ingY, width: colWidth, height: 18))
                ingY += 18
            }
            
            // Right: Instructions
            var stepY = currentY
            let rightX = margin + colWidth + 20
            let stepHeader = NSAttributedString(string: "INSTRUCTIONS", attributes: [.font: secHeaderFont, .foregroundColor: UIColor.label])
            stepHeader.draw(in: CGRect(x: rightX, y: stepY, width: colWidth, height: 20))
            stepY += 24
            
            for step in recipe.viewSortedSteps {
                let stepText = "\(step.stepNumber). \(step.instruction)"
                let stepStr = NSAttributedString(string: stepText, attributes: [.font: bodyFont, .foregroundColor: UIColor.label])
                let rect = CGRect(x: rightX, y: stepY, width: colWidth, height: 40)
                stepStr.draw(in: rect)
                stepY += 32
            }
            
            // Footer
            let footerFont = UIFont.italicSystemFont(ofSize: 9)
            let footerStr = NSAttributedString(string: "Created with RecipeApp • Exported on \(Date().formatted(date: .abbreviated, time: .shortened))", attributes: [.font: footerFont, .foregroundColor: UIColor.tertiaryLabel])
            footerStr.draw(in: CGRect(x: margin, y: pageHeight - 30, width: contentWidth, height: 20))
        }
    }
}

// SwiftUI PDF Activity Share View
struct PDFActivityView: UIViewControllerRepresentable {
    let pdfData: Data
    let title: String
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(title.replacingOccurrences(of: " ", with: "_"))_Recipe.pdf")
        try? pdfData.write(to: tempURL)
        
        let controller = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
