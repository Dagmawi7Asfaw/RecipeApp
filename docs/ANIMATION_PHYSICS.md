# 🎨 RecipeApp: Splash Screen Animation Physics

The RecipeApp splash screen utilizes Apple's advanced Core Animation physics engine combined with mathematical calculations to create a premium, organic, and lively entrance into the application. 

Here is a breakdown of the specific physics and animation models running behind the scenes:

> [!NOTE]
> The combination of these specific physics models is what elevates the app from feeling "static" to feeling "alive" and interactive, creating a strong first impression for users.

---

## 1. Spring Physics (Logo & Title Entrance)
When the app logo and title first appear, they don't just scale up evenly. They use a **spring animation model** (`.spring(response: 0.7, dampingFraction: 0.65)`):

- **Response (0.7s):** This dictates the "stiffness" of the spring. A 0.7-second response means the logo moves quickly but smoothly.
- **Damping Fraction (0.65):** This controls the "bounciness" or friction. By setting it to 0.65 (where 1.0 is completely stiff), the logo slightly overshoots its target size and bounces back into place. This gives the digital elements a sense of physical weight and momentum.

---

## 2. Trigonometry & Particle Physics (Food Emojis)
The most mathematically complex part of the splash screen is the 12 floating food emojis (`FloatingParticle`). To make them explode outward into a perfect circle, we used applied trigonometry:

- **Angles:** We divide a full circle (360 degrees) by 12, so each emoji is spaced exactly 30 degrees apart. We then convert those degrees into radians for the math engine.
- **Radius & Trajectory:** We pick a random distance (radius) for each emoji to travel outward (between 160 and 300 points). 
- **The Math:** Using `cos(angle) * radius` calculates the exact X coordinate, and `sin(angle) * radius` calculates the exact Y coordinate. 
- **Explosion & Drag:** The emojis animate to these coordinates using an `.easeOut` curve, meaning they start fast like an explosion, then slow down rapidly due to simulated "air resistance."
- **The Drift:** Once they reach their target, they enter a continuous animation loop where they randomly drift slightly up, down, left, and right, simulating floating in zero gravity or underwater.

---

## 3. Linear Momentum (Spinning Rings)
The dashed rings orbiting the logo use a completely different type of physics: **Linear Animation**.

- By using `.linear(duration: 8).repeatForever()`, the rings rotate exactly 360 degrees over 8 seconds. 
- The linear curve ensures there is no acceleration or deceleration—it spins at a constant velocity, creating a smooth, uninterrupted orbit like planetary rings. 
- **Parallax Effect:** The inner ring spins clockwise, while the outer ring spins counter-clockwise at a slightly slower speed to create an illusion of 3D depth.

---

## 4. Easing Curves (Fades, Shimmer, and Exit)
For subtle effects like the shimmer sweeping across the logo, the subtitle fading in, and the final exit transition, we use **Easing Curves** (`.easeInOut`, `.easeIn`, `.easeOut`):

- Unlike linear animations, easing curves simulate real-world acceleration. 
- For example, the shimmer effect uses `.easeInOut`. It starts moving slowly, reaches its top speed in the middle of the logo, and slows down again before finishing. This mirrors how physical objects behave when you push them—they take time to accelerate and decelerate.
