// Copyright © 2023 Big Mountain Studio. All rights reserved. Twitter: @BigMtnStudio

import Foundation
import SwiftData
import UIKit

@Model
class StepModel {
    var stepNumber: Int
    var instruction: String
    var image: Data?
    var timerDurationMinutes: Int = 0
    var recipe: RecipeModel?
    
    init(stepNumber: Int, instruction: String, image: Data? = nil, timerDurationMinutes: Int = 0, recipe: RecipeModel? = nil) {
        self.stepNumber = stepNumber
        self.instruction = instruction
        self.image = image
        self.timerDurationMinutes = timerDurationMinutes
        self.recipe = recipe
    }
}
