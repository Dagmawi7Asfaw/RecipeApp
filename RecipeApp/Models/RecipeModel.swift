import CoreLocation
import Foundation
import SwiftData
import UIKit

@Model
class RecipeModel {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \IngredientModel.recipes)
    var ingredients: [IngredientModel] = []
    @Relationship(deleteRule: .cascade, inverse: \StepModel.recipe)
    var steps: [StepModel] = []
    var image: Data?
    var category: CategoryModel?
    var minutesToCook: Int = 0
    var prepTimeMinutes: Int = 0
    var servingSize: Int = 1
    var isFavorite: Bool = false
    var tags: [String] = []
    var locationName: String?
    var latitude: Double?
    var longitude: Double?
    
    // Professional App Extensions: Nutrition & Metadata
    var calories: Int = 0
    var proteinGrams: Int = 0
    var carbsGrams: Int = 0
    var fatGrams: Int = 0
    var dietaryPreferences: [String] = [] // e.g. "Gluten-Free", "Vegetarian", "Vegan", "Keto", "High-Protein", "Halal"
    var rating: Int = 5 // 1 to 5 stars
    var userNotes: String = ""
    
    init(name: String, 
         ingredients: [IngredientModel] = [], 
         steps: [StepModel] = [], 
         image: Data? = nil, 
         category: CategoryModel? = nil, 
         minutesToCook: Int = 0, 
         prepTimeMinutes: Int = 0,
         servingSize: Int = 1,
         isFavorite: Bool = false,
         tags: [String] = [],
         locationName: String? = nil,
         latitude: Double? = nil,
         longitude: Double? = nil,
         calories: Int = 0,
         proteinGrams: Int = 0,
         carbsGrams: Int = 0,
         fatGrams: Int = 0,
         dietaryPreferences: [String] = [],
         rating: Int = 5,
         userNotes: String = "") {
        self.name = name
        self.ingredients = ingredients
        self.steps = steps
        self.image = image
        self.category = category
        self.minutesToCook = minutesToCook
        self.prepTimeMinutes = prepTimeMinutes
        self.servingSize = servingSize
        self.isFavorite = isFavorite
        self.tags = tags
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.dietaryPreferences = dietaryPreferences
        self.rating = rating
        self.userNotes = userNotes
    }
}

extension RecipeModel {
    var viewImage: UIImage? {
        guard let image else { return nil }
        return UIImage(data: image)
    }
    var viewImageWithDefault: UIImage {
        guard let image else { return UIImage(systemName: "fork.knife.circle")! }
        return UIImage(data: image) ?? UIImage(systemName: "fork.knife.circle")!
    }
    var viewCategory: String {
        category?.name ?? ""
    }
    
    var viewSortedSteps: [StepModel] {
        steps.sorted { $0.stepNumber < $1.stepNumber }
    }
    
    var viewSortedIngredients: [IngredientModel] {
        ingredients.sorted { $0.name < $1.name }
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var totalTimeMinutes: Int {
        prepTimeMinutes + minutesToCook
    }
}

extension RecipeModel {
    @MainActor
    static func insertSampleData(into context: ModelContext) {
        // MARK: - Categories (7 Continents & Classics)
        let africanCat = CategoryModel(name: "African Cuisine")
        let asianCat = CategoryModel(name: "Asian Cuisine")
        let europeanCat = CategoryModel(name: "European Cuisine")
        let northAmericanCat = CategoryModel(name: "North American Cuisine")
        let southAmericanCat = CategoryModel(name: "South American Cuisine")
        let oceanianCat = CategoryModel(name: "Oceanian Cuisine")
        let antarcticCat = CategoryModel(name: "Antarctic Expedition")
        let dessertsCat = CategoryModel(name: "Desserts")
        
        context.insert(africanCat)
        context.insert(asianCat)
        context.insert(europeanCat)
        context.insert(northAmericanCat)
        context.insert(southAmericanCat)
        context.insert(oceanianCat)
        context.insert(antarcticCat)
        context.insert(dessertsCat)
        try? context.save()
        
        // MARK: - 1. Africa
        let doroWat = RecipeModel(
            name: "Doro Wat",
            image: UIImage(named: "doro.wat")?.pngData(),
            category: africanCat,
            minutesToCook: 90,
            prepTimeMinutes: 30,
            servingSize: 6,
            isFavorite: true,
            tags: ["African", "Ethiopian", "Spicy", "Chicken", "Traditional"],
            locationName: "Finfinne Cultural Restaurant, Addis Ababa, Ethiopia",
            latitude: 9.0108,
            longitude: 38.7612,
            calories: 580,
            proteinGrams: 42,
            carbsGrams: 18,
            fatGrams: 28,
            dietaryPreferences: ["High-Protein", "Halal"],
            rating: 5,
            userNotes: "National dish of Ethiopia. Simmered slow for rich, deep berbere flavor."
        )
        context.insert(doroWat)
        
        let kitfo = RecipeModel(
            name: "Kitfo",
            image: UIImage(named: "kitfo")?.pngData(),
            category: africanCat,
            minutesToCook: 15,
            prepTimeMinutes: 15,
            servingSize: 4,
            isFavorite: true,
            tags: ["African", "Ethiopian", "Beef", "Delicacy", "Keto"],
            locationName: "Kategna Ethiopian Restaurant, Addis Ababa, Ethiopia",
            latitude: 8.9950,
            longitude: 38.7850,
            calories: 520,
            proteinGrams: 48,
            carbsGrams: 4,
            fatGrams: 34,
            dietaryPreferences: ["Keto", "High-Protein", "Gluten-Free"],
            rating: 5,
            userNotes: "Tender minced prime beef infused with spiced niter kibbeh and mitmita."
        )
        context.insert(kitfo)
        
        let shiroWat = RecipeModel(
            name: "Shiro Wat",
            image: UIImage(named: "shiro.wat")?.pngData(),
            category: africanCat,
            minutesToCook: 25,
            prepTimeMinutes: 10,
            servingSize: 4,
            isFavorite: true,
            tags: ["African", "Ethiopian", "Vegetarian", "Vegan", "Stew"],
            locationName: "Yod Abyssinia Cultural Restaurant, Addis Ababa, Ethiopia",
            latitude: 8.9890,
            longitude: 38.7885,
            calories: 340,
            proteinGrams: 18,
            carbsGrams: 46,
            fatGrams: 12,
            dietaryPreferences: ["Vegetarian", "Vegan", "Gluten-Free"],
            rating: 5,
            userNotes: "Velvety spiced chickpea and legume stew served piping hot with Injera."
        )
        context.insert(shiroWat)
        
        let beefTibs = RecipeModel(
            name: "Beef Tibs",
            image: UIImage(named: "beef.tibs")?.pngData(),
            category: africanCat,
            minutesToCook: 20,
            prepTimeMinutes: 10,
            servingSize: 4,
            isFavorite: false,
            tags: ["African", "Ethiopian", "Sautéed", "Beef", "Quick"],
            locationName: "Habesha Restaurant, Addis Ababa, Ethiopia",
            latitude: 9.0020,
            longitude: 38.7750,
            calories: 490,
            proteinGrams: 44,
            carbsGrams: 8,
            fatGrams: 30,
            dietaryPreferences: ["High-Protein", "Keto"],
            rating: 5,
            userNotes: "Sizzling sautéed beef tenderloin with rosemary, onions, and jalapeños."
        )
        context.insert(beefTibs)
        
        let jollofRice = RecipeModel(
            name: "Smoky Nigerian Jollof Rice",
            image: UIImage(named: "jollof.rice")?.pngData(),
            category: africanCat,
            minutesToCook: 45,
            prepTimeMinutes: 20,
            servingSize: 6,
            isFavorite: true,
            tags: ["African", "Nigerian", "Rice", "Spicy", "Party Food"],
            locationName: "Yellow Chilli Restaurant, Victoria Island, Lagos, Nigeria",
            latitude: 6.4281,
            longitude: 3.4219,
            calories: 450,
            proteinGrams: 14,
            carbsGrams: 68,
            fatGrams: 14,
            dietaryPreferences: ["Gluten-Free", "Vegetarian Option"],
            rating: 5,
            userNotes: "Iconic West African party rice cooked in rich roasted tomato and scotch bonnet stew."
        )
        context.insert(jollofRice)
        
        // MARK: - 2. Asia
        let tonkotsuRamen = RecipeModel(
            name: "Authentic Tonkotsu Ramen",
            image: UIImage(named: "tonkotsu.ramen")?.pngData(),
            category: asianCat,
            minutesToCook: 60,
            prepTimeMinutes: 30,
            servingSize: 2,
            isFavorite: true,
            tags: ["Asian", "Japanese", "Noodles", "Pork", "Comfort Food"],
            locationName: "Ichiran Ramen Main Branch, Fukuoka, Japan",
            latitude: 33.5904,
            longitude: 130.4017,
            calories: 680,
            proteinGrams: 32,
            carbsGrams: 74,
            fatGrams: 28,
            dietaryPreferences: ["High-Protein"],
            rating: 5,
            userNotes: "Rich 12-hour pork bone broth with springy noodles, chashu pork, and soft ajitama egg."
        )
        context.insert(tonkotsuRamen)
        
        let butterChicken = RecipeModel(
            name: "Butter Chicken (Murgh Makhani)",
            image: UIImage(named: "butter.chicken")?.pngData(),
            category: asianCat,
            minutesToCook: 40,
            prepTimeMinutes: 25,
            servingSize: 4,
            isFavorite: true,
            tags: ["Asian", "Indian", "Curry", "Creamy", "High-Protein"],
            locationName: "Moti Mahal Restaurant, Daryaganj, Old Delhi, India",
            latitude: 28.6562,
            longitude: 77.2410,
            calories: 620,
            proteinGrams: 38,
            carbsGrams: 22,
            fatGrams: 42,
            dietaryPreferences: ["High-Protein", "Halal", "Gluten-Free"],
            rating: 5,
            userNotes: "Tender tandoori chicken simmered in a velvety tomato, butter, cream, and fenugreek gravy."
        )
        context.insert(butterChicken)
        
        let padThai = RecipeModel(
            name: "Pad Thai Goong (Prawn)",
            image: UIImage(named: "pad.thai")?.pngData(),
            category: asianCat,
            minutesToCook: 20,
            prepTimeMinutes: 15,
            servingSize: 2,
            isFavorite: false,
            tags: ["Asian", "Thai", "Seafood", "Noodles", "Street Food"],
            locationName: "Thipsamai Pad Thai, Bangkok, Thailand",
            latitude: 13.7563,
            longitude: 100.5018,
            calories: 510,
            proteinGrams: 28,
            carbsGrams: 62,
            fatGrams: 16,
            dietaryPreferences: ["Dairy-Free", "High-Protein"],
            rating: 5,
            userNotes: "Wok-fried rice noodles with succulent tiger prawns, tofu, peanuts, and tamarind glaze."
        )
        context.insert(padThai)
        
        // MARK: - 3. Europe
        let beefBourguignon = RecipeModel(
            name: "French Beef Bourguignon",
            image: UIImage(named: "beef.bourguignon")?.pngData(),
            category: europeanCat,
            minutesToCook: 150,
            prepTimeMinutes: 30,
            servingSize: 6,
            isFavorite: true,
            tags: ["European", "French", "Slow-Cook", "Beef", "Gourmet"],
            locationName: "Le Bistrot Paul Bert, Paris, France",
            latitude: 48.8519,
            longitude: 2.3854,
            calories: 640,
            proteinGrams: 46,
            carbsGrams: 16,
            fatGrams: 34,
            dietaryPreferences: ["High-Protein", "Dairy-Free Option"],
            rating: 5,
            userNotes: "Prime beef braised in dry red Burgundy wine with pearl onions, mushrooms, and bouquet garni."
        )
        context.insert(beefBourguignon)
        
        let seafoodPaella = RecipeModel(
            name: "Seafood Paella Valenciana",
            image: UIImage(named: "seafood.paella")?.pngData(),
            category: europeanCat,
            minutesToCook: 45,
            prepTimeMinutes: 25,
            servingSize: 6,
            isFavorite: true,
            tags: ["European", "Spanish", "Seafood", "Saffron", "Rice"],
            locationName: "La Pepica Restaurant, Playa de la Malvarrosa, Valencia, Spain",
            latitude: 39.4699,
            longitude: -0.3242,
            calories: 560,
            proteinGrams: 36,
            carbsGrams: 64,
            fatGrams: 16,
            dietaryPreferences: ["Gluten-Free", "Dairy-Free", "High-Protein"],
            rating: 5,
            userNotes: "Golden saffron Bomba rice with mussels, tiger prawns, calamari, and crispy socarrat crust."
        )
        context.insert(seafoodPaella)
        
        let spaghettiBolognese = RecipeModel(
            name: "Spaghetti Bolognese",
            image: UIImage(resource: .spaghettiBolognese).pngData()!,
            category: europeanCat,
            minutesToCook: 80,
            prepTimeMinutes: 20,
            servingSize: 4,
            isFavorite: true,
            tags: ["European", "Italian", "Pasta", "Dinner"],
            locationName: "Osteria dell'Orsa, Bologna, Italy",
            latitude: 44.4960,
            longitude: 11.3463,
            calories: 590,
            proteinGrams: 30,
            carbsGrams: 70,
            fatGrams: 20,
            dietaryPreferences: ["High-Protein"],
            rating: 5,
            userNotes: "Slow-simmered rich Italian meat ragù tossed with al dente pasta and Parmigiano-Reggiano."
        )
        context.insert(spaghettiBolognese)
        
        let lobsterBisque = RecipeModel(
            name: "Lobster Bisque",
            image: UIImage(resource: .lobsterBisque).pngData()!,
            category: europeanCat,
            minutesToCook: 90,
            prepTimeMinutes: 20,
            servingSize: 6,
            isFavorite: true,
            tags: ["European", "French", "Seafood", "Gourmet", "Soup"],
            locationName: "Le Café de la Paix, Paris, France",
            latitude: 48.8708,
            longitude: 2.3315,
            calories: 420,
            proteinGrams: 22,
            carbsGrams: 14,
            fatGrams: 30,
            dietaryPreferences: ["Gluten-Free Option"],
            rating: 5,
            userNotes: "Smooth, velvety cream soup made from roasted lobster shells and dry white wine."
        )
        context.insert(lobsterBisque)
        
        // MARK: - 4. North America
        let birriaTacos = RecipeModel(
            name: "Birria QuesaTacos with Consomé",
            image: UIImage(named: "birria.tacos")?.pngData(),
            category: northAmericanCat,
            minutesToCook: 180,
            prepTimeMinutes: 30,
            servingSize: 6,
            isFavorite: true,
            tags: ["North American", "Mexican", "Tacos", "Beef", "Cheese"],
            locationName: "Taquería El Compa, Guadalajara, Jalisco, Mexico",
            latitude: 20.6597,
            longitude: -103.3496,
            calories: 610,
            proteinGrams: 40,
            carbsGrams: 36,
            fatGrams: 32,
            dietaryPreferences: ["Gluten-Free", "High-Protein"],
            rating: 5,
            userNotes: "Crispy chili-dipped tortillas packed with shredded slow-braised beef and melted Oaxaca cheese."
        )
        context.insert(birriaTacos)
        
        let quebecPoutine = RecipeModel(
            name: "Authentic Quebec Poutine",
            image: UIImage(named: "quebec.poutine")?.pngData(),
            category: northAmericanCat,
            minutesToCook: 30,
            prepTimeMinutes: 15,
            servingSize: 4,
            isFavorite: false,
            tags: ["North American", "Canadian", "Comfort Food", "Cheese Curds"],
            locationName: "La Banquise, Montreal, Quebec, Canada",
            latitude: 45.5255,
            longitude: -73.5746,
            calories: 720,
            proteinGrams: 24,
            carbsGrams: 78,
            fatGrams: 38,
            dietaryPreferences: ["Vegetarian Option"],
            rating: 5,
            userNotes: "Hand-cut crispy fries topped with fresh squeaky cheese curds and piping hot beef gravy."
        )
        context.insert(quebecPoutine)
        
        let grilledSalmon = RecipeModel(
            name: "Pacific Northwest Grilled Salmon",
            image: UIImage(resource: .grilledSalmon).pngData()!,
            category: northAmericanCat,
            minutesToCook: 25,
            prepTimeMinutes: 10,
            servingSize: 3,
            isFavorite: true,
            tags: ["North American", "American", "Seafood", "Healthy", "Keto"],
            locationName: "Pike Place Seafood Market, Seattle, WA, USA",
            latitude: 47.6097,
            longitude: -122.3422,
            calories: 410,
            proteinGrams: 38,
            carbsGrams: 2,
            fatGrams: 26,
            dietaryPreferences: ["Keto", "High-Protein", "Gluten-Free", "Dairy-Free"],
            rating: 5,
            userNotes: "Wild cedar-plank grilled salmon seasoned with fresh dill, lemon zest, and garlic."
        )
        context.insert(grilledSalmon)
        
        // MARK: - 5. South America
        let peruvianCeviche = RecipeModel(
            name: "Peruvian Ceviche Clásico",
            image: UIImage(named: "peruvian.ceviche")?.pngData(),
            category: southAmericanCat,
            minutesToCook: 15,
            prepTimeMinutes: 20,
            servingSize: 4,
            isFavorite: true,
            tags: ["South American", "Peruvian", "Seafood", "Gluten-Free", "Fresh"],
            locationName: "La Mar Cebichería, Miraflores, Lima, Peru",
            latitude: -12.1219,
            longitude: -77.0371,
            calories: 290,
            proteinGrams: 34,
            carbsGrams: 26,
            fatGrams: 4,
            dietaryPreferences: ["Gluten-Free", "Dairy-Free", "Low-Carb", "High-Protein"],
            rating: 5,
            userNotes: "Fresh sea bass cured in vibrant Leche de Tigre with sweet potato, choclo corn, and red onions."
        )
        context.insert(peruvianCeviche)
        
        // MARK: - 6. Oceania / Australia
        let aussieBarramundi = RecipeModel(
            name: "Pan-Seared Aussie Barramundi",
            image: UIImage(named: "aussie.barramundi")?.pngData(),
            category: oceanianCat,
            minutesToCook: 20,
            prepTimeMinutes: 10,
            servingSize: 2,
            isFavorite: true,
            tags: ["Oceanian", "Australian", "Seafood", "Keto", "High-Protein"],
            locationName: "Sydney Fish Market, Pyrmont, Sydney, Australia",
            latitude: -33.8726,
            longitude: 151.1925,
            calories: 380,
            proteinGrams: 42,
            carbsGrams: 4,
            fatGrams: 20,
            dietaryPreferences: ["Keto", "High-Protein", "Gluten-Free"],
            rating: 5,
            userNotes: "Crispy-skin wild Barramundi fillet with lemon myrtle herb butter and charred asparagus."
        )
        context.insert(aussieBarramundi)
        
        // MARK: - 7. Antarctica
        let southPoleChili = RecipeModel(
            name: "South Pole Station Expedition Chili",
            image: UIImage(named: "south.pole.chili")?.pngData(),
            category: antarcticCat,
            minutesToCook: 75,
            prepTimeMinutes: 20,
            servingSize: 8,
            isFavorite: true,
            tags: ["Antarctica", "Polar Expedition", "Hearty", "High-Energy", "Chili"],
            locationName: "Amundsen-Scott South Pole Station, Antarctica",
            latitude: -90.0000,
            longitude: 0.0000,
            calories: 620,
            proteinGrams: 46,
            carbsGrams: 48,
            fatGrams: 26,
            dietaryPreferences: ["High-Protein", "Comfort Food"],
            rating: 5,
            userNotes: "Deeply warming smoked brisket and three-bean chili cooked for winter-over research teams."
        )
        context.insert(southPoleChili)
        
        // MARK: - Desserts
        let applePie = RecipeModel(
            name: "Classic Apple Pie",
            image: UIImage(resource: .applePie).pngData()!,
            category: dessertsCat,
            minutesToCook: 75,
            prepTimeMinutes: 30,
            servingSize: 8,
            isFavorite: true,
            tags: ["Dessert", "Baking", "American"],
            locationName: "Vermont Apple Orchard, USA",
            latitude: 44.5588,
            longitude: -72.5778,
            calories: 410,
            proteinGrams: 4,
            carbsGrams: 58,
            fatGrams: 18,
            dietaryPreferences: ["Vegetarian"],
            rating: 5,
            userNotes: "Golden flaky double-crust pie filled with cinnamon-spiced Honeycrisp apples."
        )
        context.insert(applePie)
        
        try? context.save()

        // MARK: - Ingredients Seeding
        // Ethiopian
        let chickenPieces = IngredientModel(name: "Whole Chicken (cut in 12 pieces)", quantity: "1")
        let redOnions = IngredientModel(name: "Red Onions (finely chopped)", quantity: "5 cups")
        let berbere = IngredientModel(name: "Berbere Spice Blend", quantity: "½ cup")
        let kibbeh = IngredientModel(name: "Niter Kibbeh (Spiced Clarified Butter)", quantity: "½ cup")
        let eggs = IngredientModel(name: "Hard-boiled Eggs", quantity: "6")
        let garlicGinger = IngredientModel(name: "Garlic & Ginger Paste", quantity: "2 tablespoons")
        let lemonJuice = IngredientModel(name: "Fresh Lemon Juice", quantity: "2 tablespoons")
        
        let primeBeef = IngredientModel(name: "Prime Beef (finely minced)", quantity: "1 lb")
        let mitmita = IngredientModel(name: "Mitmita Spice", quantity: "1 ½ tablespoons")
        let korerima = IngredientModel(name: "Korerima (Ethiopian Cardamom)", quantity: "1 teaspoon")
        let ayib = IngredientModel(name: "Ayib (Cottage Cheese)", quantity: "1 cup")
        let gomen = IngredientModel(name: "Gomen (Collard Greens)", quantity: "1 cup")
        
        let shiroPowder = IngredientModel(name: "Shiro Powder (Spiced Chickpea Flour)", quantity: "1 cup")
        let mincedGarlic = IngredientModel(name: "Minced Garlic", quantity: "4 cloves")
        let brothWater = IngredientModel(name: "Water or Vegetable Broth", quantity: "3 cups")
        let tomatoPaste = IngredientModel(name: "Tomato Paste", quantity: "2 tablespoons")
        
        let beefTenderloin = IngredientModel(name: "Beef Tenderloin (cubed)", quantity: "1.5 lbs")
        let slicedOnion = IngredientModel(name: "Red Onion (sliced)", quantity: "1 large")
        let jalapenos = IngredientModel(name: "Jalapeño Peppers (sliced)", quantity: "2")
        let rosemary = IngredientModel(name: "Fresh Rosemary Sprigs", quantity: "3")
        let awaze = IngredientModel(name: "Awaze Paste", quantity: "1 tablespoon")
        
        // Nigerian Jollof
        let jollofRiceGrain = IngredientModel(name: "Long-grain Parboiled Rice", quantity: "3 cups")
        let plumTomatoes = IngredientModel(name: "Plum Tomatoes (blended)", quantity: "6")
        let redBellPeppers = IngredientModel(name: "Red Bell Peppers (Tatashe)", quantity: "3")
        let scotchBonnets = IngredientModel(name: "Scotch Bonnet Peppers", quantity: "2")
        let curryThyme = IngredientModel(name: "Curry Powder & Dried Thyme", quantity: "1 tablespoon")
        let bayLeaves = IngredientModel(name: "Dried Bay Leaves", quantity: "4")
        let chickenStock = IngredientModel(name: "Rich Chicken Stock", quantity: "4 cups")
        
        // Japanese Ramen
        let ramenNoodles = IngredientModel(name: "Fresh Ramen Noodles", quantity: "2 portions")
        let porkBroth = IngredientModel(name: "Tonkotsu Pork Bone Broth", quantity: "4 cups")
        let chashuPork = IngredientModel(name: "Chashu Pork Belly Slices", quantity: "4 slices")
        let ajitamaEgg = IngredientModel(name: "Ajitsuke Tamago (Marinated Soft Egg)", quantity: "2")
        let menma = IngredientModel(name: "Menma Bamboo Shoots", quantity: "¼ cup")
        let scallions = IngredientModel(name: "Chopped Scallions", quantity: "½ cup")
        let nori = IngredientModel(name: "Nori Seaweed Sheets", quantity: "2")
        
        // Indian Butter Chicken
        let chickenThighs = IngredientModel(name: "Boneless Chicken Thighs (cubed)", quantity: "1.5 lbs")
        let greekYogurt = IngredientModel(name: "Plain Greek Yogurt", quantity: "½ cup")
        let garamMasala = IngredientModel(name: "Garam Masala", quantity: "1 tablespoon")
        let butterIndia = IngredientModel(name: "Unsalted Butter", quantity: "4 tablespoons")
        let heavyCream = IngredientModel(name: "Heavy Cream", quantity: "¾ cup")
        let kasuriMethi = IngredientModel(name: "Kasuri Methi (Dried Fenugreek)", quantity: "1 tablespoon")
        let tomatoPuree = IngredientModel(name: "Crushed Canned Tomatoes", quantity: "1 (14 oz) can")
        
        // Thai Pad Thai
        let padThaiNoodles = IngredientModel(name: "Flat Rice Noodles", quantity: "8 oz")
        let tigerPrawns = IngredientModel(name: "Jumbo Tiger Prawns", quantity: "8")
        let tamarindPaste = IngredientModel(name: "Tamarind Concentrate", quantity: "3 tablespoons")
        let fishSauce = IngredientModel(name: "Fish Sauce", quantity: "2 tablespoons")
        let palmSugar = IngredientModel(name: "Palm Sugar", quantity: "2 tablespoons")
        let beanSprouts = IngredientModel(name: "Fresh Bean Sprouts", quantity: "1 cup")
        let crushedPeanuts = IngredientModel(name: "Crushed Roasted Peanuts", quantity: "¼ cup")
        let firmTofu = IngredientModel(name: "Firm Tofu (cubed)", quantity: "½ cup")
        
        // French Beef Bourguignon
        let chuckRoast = IngredientModel(name: "Beef Chuck (cut into 2-inch chunks)", quantity: "3 lbs")
        let burgundyWine = IngredientModel(name: "Red Burgundy Wine (Pinot Noir)", quantity: "1 bottle (750ml)")
        let baconLardons = IngredientModel(name: "Thick-Cut Bacon Lardons", quantity: "6 oz")
        let pearlOnions = IngredientModel(name: "Fresh Pearl Onions (peeled)", quantity: "1 cup")
        let creminiMushrooms = IngredientModel(name: "Cremini Mushrooms (quartered)", quantity: "8 oz")
        let beefStock = IngredientModel(name: "Dark Beef Bone Broth", quantity: "2 cups")
        let freshThyme = IngredientModel(name: "Fresh Thyme & Bay Leaf", quantity: "4 sprigs")
        
        // Spanish Paella
        let bombaRice = IngredientModel(name: "Spanish Bomba Rice", quantity: "2 cups")
        let saffron = IngredientModel(name: "Spanish Saffron Threads", quantity: "1 pinch (½ tsp)")
        let mussels = IngredientModel(name: "Fresh Black Mussels", quantity: "12")
        let jumboShrimp = IngredientModel(name: "Head-on Jumbo Shrimp", quantity: "8")
        let calamari = IngredientModel(name: "Calamari Squid Rings", quantity: "6 oz")
        let fishBroth = IngredientModel(name: "Seafood/Fish Stock", quantity: "4 cups")
        let smokedPaprika = IngredientModel(name: "Spanish Smoked Paprika (Pimentón)", quantity: "1 teaspoon")
        
        // Italian Spaghetti Bolognese
        let groundBeefPork = IngredientModel(name: "Ground Beef & Pork Blend", quantity: "1 lb")
        let spaghettiPasta = IngredientModel(name: "Spaghetti Pasta", quantity: "1 lb")
        let soffritto = IngredientModel(name: "Soffritto (Onion, Celery, Carrot)", quantity: "1 cup")
        let parmigiano = IngredientModel(name: "Parmigiano-Reggiano (grated)", quantity: "½ cup")
        
        // Mexican Birria Tacos
        let beefChuckBirria = IngredientModel(name: "Beef Chuck & Short Ribs", quantity: "3 lbs")
        let guajilloChiles = IngredientModel(name: "Dried Guajillo Chiles", quantity: "5")
        let anchoChiles = IngredientModel(name: "Dried Ancho Chiles", quantity: "2")
        let oaxacaCheese = IngredientModel(name: "Oaxaca or Monterey Jack Cheese", quantity: "2 cups")
        let cornTortillas = IngredientModel(name: "White Corn Tortillas", quantity: "12")
        let cilantroLime = IngredientModel(name: "Fresh Cilantro & Limes", quantity: "1 bunch")
        
        // Canadian Poutine
        let russetPotatoes = IngredientModel(name: "Russet Potatoes (cut into fries)", quantity: "4 large")
        let cheeseCurds = IngredientModel(name: "Fresh White Squeaky Cheese Curds", quantity: "2 cups")
        let poutineGravy = IngredientModel(name: "Rich Brown Poutine Gravy", quantity: "2 cups")
        
        // American Grilled Salmon
        let wildSalmon = IngredientModel(name: "Wild Salmon Fillets", quantity: "3")
        let lemonDill = IngredientModel(name: "Fresh Dill & Lemon", quantity: "2 tablespoons")
        let oliveOil = IngredientModel(name: "Extra Virgin Olive Oil", quantity: "2 tablespoons")
        
        // Peruvian Ceviche
        let corvinaBass = IngredientModel(name: "Fresh Sea Bass or Corvina Fillets (cubed)", quantity: "1.5 lbs")
        let limeJuicePeru = IngredientModel(name: "Fresh Key Lime Juice", quantity: "¾ cup")
        let rocotoChili = IngredientModel(name: "Rocoto or Aji Limo Chili (minced)", quantity: "1")
        let redOnionPeru = IngredientModel(name: "Red Onion (julienned into thin feathers)", quantity: "1 medium")
        let sweetPotato = IngredientModel(name: "Boiled Sweet Potato Wheel (Camote)", quantity: "1 large")
        let chocloCorn = IngredientModel(name: "Giant Andean Choclo & Cancha Corn", quantity: "1 cup")
        
        // Australian Barramundi
        let barramundiFillets = IngredientModel(name: "Wild Australian Barramundi Fillets (skin-on)", quantity: "2")
        let lemonMyrtleButter = IngredientModel(name: "Butter with Lemon Zest & Sea Salt", quantity: "3 tablespoons")
        let asparagus = IngredientModel(name: "Baby Asparagus Spears", quantity: "1 bunch")
        
        // Antarctic Expedition Chili
        let smokedBrisket = IngredientModel(name: "Smoked Beef Brisket or Ground Chuck", quantity: "2 lbs")
        let kidneyBeans = IngredientModel(name: "Kidney Beans & Black Beans", quantity: "2 (15 oz) cans")
        let chiliPowderBlend = IngredientModel(name: "Ancho & Chipotle Chili Spice Blend", quantity: "3 tablespoons")
        let darkChocolate = IngredientModel(name: "Dark Unsweetened Cocoa/Chocolate", quantity: "1 oz")
        let cheddarCornbread = IngredientModel(name: "Sharp Cheddar & Warm Skillet Cornbread", quantity: "for serving")
        
        // American Apple Pie
        let apples = IngredientModel(name: "Honeycrisp & Granny Smith Apples", quantity: "6 large")
        let pieCrust = IngredientModel(name: "Double Flaky Butter Pie Crust", quantity: "1 package")
        let cinnamonSugar = IngredientModel(name: "Cinnamon & Brown Sugar", quantity: "¾ cup")
        
        // Assign Ingredients
        doroWat.ingredients = [chickenPieces, redOnions, berbere, kibbeh, eggs, garlicGinger, lemonJuice]
        kitfo.ingredients = [primeBeef, kibbeh, mitmita, korerima, ayib, gomen]
        shiroWat.ingredients = [shiroPowder, redOnions, mincedGarlic, berbere, kibbeh, brothWater, tomatoPaste]
        beefTibs.ingredients = [beefTenderloin, slicedOnion, jalapenos, rosemary, kibbeh, mincedGarlic, awaze]
        jollofRice.ingredients = [jollofRiceGrain, plumTomatoes, redBellPeppers, scotchBonnets, curryThyme, bayLeaves, chickenStock, redOnions]
        
        tonkotsuRamen.ingredients = [ramenNoodles, porkBroth, chashuPork, ajitamaEgg, menma, scallions, nori]
        butterChicken.ingredients = [chickenThighs, greekYogurt, garamMasala, butterIndia, heavyCream, kasuriMethi, tomatoPuree, garlicGinger]
        padThai.ingredients = [padThaiNoodles, tigerPrawns, tamarindPaste, fishSauce, palmSugar, beanSprouts, crushedPeanuts, firmTofu]
        
        beefBourguignon.ingredients = [chuckRoast, burgundyWine, baconLardons, pearlOnions, creminiMushrooms, beefStock, freshThyme, tomatoPaste]
        seafoodPaella.ingredients = [bombaRice, saffron, mussels, jumboShrimp, calamari, fishBroth, smokedPaprika, plumTomatoes]
        spaghettiBolognese.ingredients = [groundBeefPork, spaghettiPasta, soffritto, tomatoPuree, parmigiano]
        lobsterBisque.ingredients = [chickenStock, heavyCream, tomatoPaste, butterIndia]
        
        birriaTacos.ingredients = [beefChuckBirria, guajilloChiles, anchoChiles, oaxacaCheese, cornTortillas, cilantroLime, slicedOnion]
        quebecPoutine.ingredients = [russetPotatoes, cheeseCurds, poutineGravy]
        grilledSalmon.ingredients = [wildSalmon, lemonDill, oliveOil]
        
        peruvianCeviche.ingredients = [corvinaBass, limeJuicePeru, rocotoChili, redOnionPeru, sweetPotato, chocloCorn]
        aussieBarramundi.ingredients = [barramundiFillets, lemonMyrtleButter, asparagus, oliveOil]
        southPoleChili.ingredients = [smokedBrisket, kidneyBeans, chiliPowderBlend, darkChocolate, cheddarCornbread, tomatoPuree]
        applePie.ingredients = [apples, pieCrust, cinnamonSugar]
        
        try? context.save()
        
        // MARK: - Steps Seeding
        // Doro Wat
        doroWat.steps = [
            StepModel(stepNumber: 1, instruction: "Marinate chicken pieces in fresh lemon juice and sea salt for 30 minutes.", timerDurationMinutes: 30),
            StepModel(stepNumber: 2, instruction: "In a heavy pot, dry-cook finely chopped red onions over medium heat for 45 minutes until deep caramel brown.", timerDurationMinutes: 45),
            StepModel(stepNumber: 3, instruction: "Add Niter Kibbeh spiced butter, garlic, ginger, and Berbere spice blend. Sauté for 10 minutes until aromatic.", timerDurationMinutes: 10),
            StepModel(stepNumber: 4, instruction: "Add chicken pieces and 1 cup of warm water. Simmer covered on low heat for 35 minutes until chicken is meltingly tender.", timerDurationMinutes: 35),
            StepModel(stepNumber: 5, instruction: "Score hard-boiled eggs with shallow slits and submerge into sauce. Simmer 10 minutes and serve warm with fresh Injera.", timerDurationMinutes: 10)
        ]
        
        // Kitfo
        kitfo.steps = [
            StepModel(stepNumber: 1, instruction: "Finely mince lean prime beef using a very sharp chilled chef knife.", timerDurationMinutes: 10),
            StepModel(stepNumber: 2, instruction: "Gently warm Niter Kibbeh spiced butter over low heat until liquid.", timerDurationMinutes: 3),
            StepModel(stepNumber: 3, instruction: "In a warmed bowl, thoroughly combine beef, warm Niter Kibbeh, Mitmita spice, and Korerima.", timerDurationMinutes: 5),
            StepModel(stepNumber: 4, instruction: "Serve immediately alongside Ayib cottage cheese, steamed Gomen greens, and fresh Injera.", timerDurationMinutes: 0)
        ]
        
        // Shiro Wat
        shiroWat.steps = [
            StepModel(stepNumber: 1, instruction: "Sauté minced red onion and garlic in a clay pot for 5 minutes, then stir in tomato paste and Kibbeh.", timerDurationMinutes: 5),
            StepModel(stepNumber: 2, instruction: "Add Berbere spice blend and pour in 3 cups of water; bring to a rolling boil.", timerDurationMinutes: 5),
            StepModel(stepNumber: 3, instruction: "Gradually whisk in Shiro chickpea powder to prevent clumps. Lower heat to simmer for 15 minutes while stirring.", timerDurationMinutes: 15),
            StepModel(stepNumber: 4, instruction: "Serve bubbling hot in traditional clay pot with fresh soft Injera.", timerDurationMinutes: 0)
        ]
        
        // Beef Tibs
        beefTibs.steps = [
            StepModel(stepNumber: 1, instruction: "Heat a heavy cast iron skillet over high heat until smoking hot.", timerDurationMinutes: 3),
            StepModel(stepNumber: 2, instruction: "Melt Niter Kibbeh and sear beef cubes in a single layer for 5 minutes until browned and juicy.", timerDurationMinutes: 5),
            StepModel(stepNumber: 3, instruction: "Toss in sliced red onions, garlic, and fresh rosemary sprigs. Sauté for 4 minutes until onions soften.", timerDurationMinutes: 4),
            StepModel(stepNumber: 4, instruction: "Add sliced jalapeños and a spoonful of Awaze chili paste. Toss for 2 minutes and transfer to a sizzling platter.", timerDurationMinutes: 2)
        ]
        
        // Jollof Rice
        jollofRice.steps = [
            StepModel(stepNumber: 1, instruction: "Blend tomatoes, red bell peppers, scotch bonnets, onions, and garlic into a smooth puree.", timerDurationMinutes: 5),
            StepModel(stepNumber: 2, instruction: "Heat vegetable oil in a large pot and fry sliced onions and tomato paste until deep red and fragrant.", timerDurationMinutes: 10),
            StepModel(stepNumber: 3, instruction: "Pour in blended pepper mix, curry powder, thyme, and bay leaves. Fry for 20 minutes until oil floats to top.", timerDurationMinutes: 20),
            StepModel(stepNumber: 4, instruction: "Stir in washed parboiled rice and rich chicken stock. Cover tightly with foil and pot lid.", timerDurationMinutes: 5),
            StepModel(stepNumber: 5, instruction: "Cook on low heat for 35 minutes until rice is tender. Allow bottom to lightly smoke for authentic party flavor.", timerDurationMinutes: 35)
        ]
        
        // Tonkotsu Ramen
        tonkotsuRamen.steps = [
            StepModel(stepNumber: 1, instruction: "Heat rich pork bone broth in a saucepan with soy tare seasoning until piping hot.", timerDurationMinutes: 10),
            StepModel(stepNumber: 2, instruction: "Boil fresh ramen noodles in rolling water for exactly 90 seconds for firm 'katame' texture.", timerDurationMinutes: 2),
            StepModel(stepNumber: 3, instruction: "Warm ramen bowls, pour in hot broth, and slide drained noodles gently into soup.", timerDurationMinutes: 2),
            StepModel(stepNumber: 4, instruction: "Top with torched chashu pork slices, halved ajitama soft egg, menma bamboo shoots, scallions, and nori sheet.", timerDurationMinutes: 2)
        ]
        
        // Butter Chicken
        butterChicken.steps = [
            StepModel(stepNumber: 1, instruction: "Marinate chicken in yogurt, garlic-ginger paste, garam masala, and chili for at least 30 minutes.", timerDurationMinutes: 30),
            StepModel(stepNumber: 2, instruction: "Sear marinated chicken chunks in a smoking hot pan or broiler for 8 minutes until charred on edges.", timerDurationMinutes: 8),
            StepModel(stepNumber: 3, instruction: "In another pan, melt butter and simmer crushed tomatoes, spices, and ginger for 15 minutes into a silky sauce.", timerDurationMinutes: 15),
            StepModel(stepNumber: 4, instruction: "Pour in heavy cream, add charred chicken pieces, and crush Kasuri Methi fenugreek over top. Simmer 10 minutes.", timerDurationMinutes: 10),
            StepModel(stepNumber: 5, instruction: "Serve with warm garlic naan and steamed fragrant basmati rice.", timerDurationMinutes: 0)
        ]
        
        // Pad Thai
        padThai.steps = [
            StepModel(stepNumber: 1, instruction: "Soak rice noodles in warm water for 25 minutes until pliable but still firm.", timerDurationMinutes: 25),
            StepModel(stepNumber: 2, instruction: "Whisk tamarind concentrate, fish sauce, and palm sugar in a bowl to make pad thai sauce.", timerDurationMinutes: 3),
            StepModel(stepNumber: 3, instruction: "Heat wok over high heat, sear tiger prawns and tofu cubes for 3 minutes, then push to the side.", timerDurationMinutes: 3),
            StepModel(stepNumber: 4, instruction: "Crack in an egg and scramble, then add drained noodles and pour sauce over. Toss vigorously for 3 minutes.", timerDurationMinutes: 3),
            StepModel(stepNumber: 5, instruction: "Fold in bean sprouts and garlic chives. Plate with crushed peanuts, chili flakes, and fresh lime wedges.", timerDurationMinutes: 1)
        ]
        
        // Beef Bourguignon
        beefBourguignon.steps = [
            StepModel(stepNumber: 1, instruction: "Crisp bacon lardons in a heavy Dutch oven, then remove and brown beef cubes in rendered bacon fat.", timerDurationMinutes: 12),
            StepModel(stepNumber: 2, instruction: "Sauté sliced carrots and onions in pot, stir in tomato paste and flour to coat.", timerDurationMinutes: 5),
            StepModel(stepNumber: 3, instruction: "Pour in red Burgundy wine and dark beef broth, return beef and bacon, and add bouquet garni herbs.", timerDurationMinutes: 5),
            StepModel(stepNumber: 4, instruction: "Cover and braise in oven at 325°F (160°C) for 2.5 hours until beef is fork tender.", timerDurationMinutes: 150),
            StepModel(stepNumber: 5, instruction: "Sauté pearl onions and mushrooms in butter, fold into stew 15 minutes before serving with crusty French bread.", timerDurationMinutes: 15)
        ]
        
        // Paella
        seafoodPaella.steps = [
            StepModel(stepNumber: 1, instruction: "Steep saffron threads in warm seafood stock for 10 minutes to bloom aroma.", timerDurationMinutes: 10),
            StepModel(stepNumber: 2, instruction: "Heat olive oil in wide paella pan; sear shrimp and calamari for 3 minutes and set aside.", timerDurationMinutes: 3),
            StepModel(stepNumber: 3, instruction: "Sauté grated tomatoes, garlic, and smoked paprika into a rich sofrito base.", timerDurationMinutes: 6),
            StepModel(stepNumber: 4, instruction: "Add Bomba rice and toast for 2 minutes, then pour in warm saffron seafood broth. Do NOT stir after this point.", timerDurationMinutes: 10),
            StepModel(stepNumber: 5, instruction: "Simmer for 15 minutes, arrange mussels and shrimp on top, and crank heat for last 2 minutes for crispy socarrat.", timerDurationMinutes: 17)
        ]
        
        // Birria Tacos
        birriaTacos.steps = [
            StepModel(stepNumber: 1, instruction: "Toast dried guajillo and ancho chiles in a dry skillet, then rehydrate in boiling water for 15 minutes.", timerDurationMinutes: 15),
            StepModel(stepNumber: 2, instruction: "Blend chiles with onions, garlic, vinegar, cumin, and Mexican oregano into a smooth marinade.", timerDurationMinutes: 5),
            StepModel(stepNumber: 3, instruction: "Sear beef in a Dutch oven, pour marinade and broth over, and braise on low for 3 hours until shreds effortlessly.", timerDurationMinutes: 180),
            StepModel(stepNumber: 4, instruction: "Skim orange chili fat from top of broth. Dip corn tortillas in fat and lay on a hot flat griddle.", timerDurationMinutes: 5),
            StepModel(stepNumber: 5, instruction: "Layer with shredded beef and Oaxaca cheese, fold in half, and fry until crisp. Serve with hot consomé broth for dipping.", timerDurationMinutes: 6)
        ]
        
        // Poutine
        quebecPoutine.steps = [
            StepModel(stepNumber: 1, instruction: "Cut russet potatoes into fries and soak in ice water for 30 minutes to remove excess starch.", timerDurationMinutes: 30),
            StepModel(stepNumber: 2, instruction: "Double-fry potatoes: first at 325°F for 5 minutes, then at 375°F for 3 minutes until golden and super crispy.", timerDurationMinutes: 8),
            StepModel(stepNumber: 3, instruction: "Simmer velvety rich beef poutine gravy in a saucepan until steaming hot.", timerDurationMinutes: 5),
            StepModel(stepNumber: 4, instruction: "Place hot fries in a bowl, scatter generous room-temperature squeaky cheese curds, and ladle boiling gravy immediately.", timerDurationMinutes: 2)
        ]
        
        // Peruvian Ceviche
        peruvianCeviche.steps = [
            StepModel(stepNumber: 1, instruction: "Cut ultra-fresh sea bass into 3/4-inch cubes and keep chilled in a cold bowl.", timerDurationMinutes: 5),
            StepModel(stepNumber: 2, instruction: "Gently squeeze fresh key limes (do not over-squeeze to avoid bitter oils).", timerDurationMinutes: 5),
            StepModel(stepNumber: 3, instruction: "Toss fish cubes with sea salt, minced rocoto chili, fresh cilantro, and freshly squeezed lime juice for 2 minutes.", timerDurationMinutes: 2),
            StepModel(stepNumber: 4, instruction: "Fold in thinly sliced red onion feathers. Serve immediately with glazed sweet potato, choclo corn, and cancha.", timerDurationMinutes: 2)
        ]
        
        // Australian Barramundi
        aussieBarramundi.steps = [
            StepModel(stepNumber: 1, instruction: "Score fish skin with fine shallow cuts and pat completely dry with paper towels.", timerDurationMinutes: 3),
            StepModel(stepNumber: 2, instruction: "Heat olive oil in a heavy stainless steel skillet until shimmering.", timerDurationMinutes: 3),
            StepModel(stepNumber: 3, instruction: "Press barramundi skin-side down firmly for 4 minutes until skin is ultra-crisp.", timerDurationMinutes: 4),
            StepModel(stepNumber: 4, instruction: "Flip fish, add butter, fresh lemon zest, sea salt, and baby asparagus to pan. Baste fish for 2 minutes and serve.", timerDurationMinutes: 3)
        ]
        
        // South Pole Chili
        southPoleChili.steps = [
            StepModel(stepNumber: 1, instruction: "In a large stockpot, brown smoked brisket or ground beef with chopped onions and garlic.", timerDurationMinutes: 10),
            StepModel(stepNumber: 2, instruction: "Stir in ancho chili blend, cumin, smoked paprika, and tomato puree; toast for 3 minutes.", timerDurationMinutes: 3),
            StepModel(stepNumber: 3, instruction: "Add kidney beans, black beans, beef bone broth, and a square of dark unsweetened chocolate.", timerDurationMinutes: 5),
            StepModel(stepNumber: 4, instruction: "Simmer uncovered on low heat for 60 minutes until thick, hearty, and aromatic.", timerDurationMinutes: 60),
            StepModel(stepNumber: 5, instruction: "Ladle into steaming mugs, top with aged sharp cheddar, and serve with hot skillet cornbread.", timerDurationMinutes: 2)
        ]
        
        // Apple Pie
        applePie.steps = [
            StepModel(stepNumber: 1, instruction: "Peel and slice Honeycrisp and Granny Smith apples into uniform 1/4-inch slices.", timerDurationMinutes: 15),
            StepModel(stepNumber: 2, instruction: "Toss sliced apples with cinnamon, nutmeg, brown sugar, lemon juice, and flour.", timerDurationMinutes: 5),
            StepModel(stepNumber: 3, instruction: "Roll out pie dough and line pie dish. Mound spiced apples high in center and top with lattice crust.", timerDurationMinutes: 15),
            StepModel(stepNumber: 4, instruction: "Brush with egg wash, sprinkle coarse sugar, and bake at 400°F (200°C) for 50 minutes until golden bubbling.", timerDurationMinutes: 50)
        ]
        
        try? context.save()
    }

    @MainActor
    static var preview: ModelContainer {
        let container = try! ModelContainer(for: RecipeModel.self,
                                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        insertSampleData(into: container.mainContext)
        return container
    }
}
