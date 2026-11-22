Role: You are an expert iOS Developer specializing in Swift and SwiftUI/UIKit. Please review my current Tic-Tac-Toe source code, refactor it, and upgrade it into a fully-featured, production-ready game based on the requirements below.
1. Core Logic Upgrade (Infinite Board):
Transform the standard 3x3 grid into an infinite board (Infinite Grid). The board should allow users to pan and scroll in all directions (consider using ScrollView in SwiftUI or UIScrollView in UIKit).
Win Condition Update: Since the board is infinite, update the winning logic to 5-in-a-row (Gomoku/Caro rules) horizontally, vertically, or diagonally.
2. UI/UX Requirements (Making it a "Real Game"):
Polished UI: Add smooth animations when placing a move and highlight the winning line when a game ends.
Color Rules: The X (Cross) must be Red, and the O (Nought) must be Black.
The UI must be responsive and adapt well to different screen sizes (iPhone and iPad).
3. Data Management (Match History):
Implement a match history system to save the player's past games. Please use SwiftData, CoreData, or UserDefaults (if the data model is simple enough).
The saved data should include: Date/Time of the match, Result (Win/Loss/Draw), and Total Moves.
Create a History View or a mini Leaderboard where players can view their past match records.
4. Code Architecture & Optimization:
Write clean, modular code following the MVVM architecture. Separate the Views, ViewModels, and Data Models.
Performance Optimization: Optimize the rendering for the infinite board. Use a dictionary ([Coordinate: Player]) or a Hashable struct to store coordinates instead of a massive 2D array. Ensure that the app maintains 60fps by only rendering the visible cells on the screen (e.g., using LazyVGrid/LazyHGrid efficiently or a custom Canvas drawing approach).