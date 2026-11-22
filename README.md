# TicTacToe iOS — Five in a Row

A local, two-player iOS game built with Swift and UIKit. This project extends [CodeWithCal's TicTacToe starter](https://github.com/codeWithCal/TicTacToeSwiftXcode) into a five-in-a-row game with MVVM, a tiled board, and persistent match summaries.

## Features

- **Five-in-a-row rules:** X starts, players alternate, and five or more consecutive pieces win horizontally, vertically, or along either diagonal. Occupied cells and moves after a win are rejected.
- **Sparse board:** occupied cells live in a `[Coordinate: Player]` dictionary rather than a dense two-dimensional array.
- **Pan and zoom:** drag the board in either direction and pinch between 0.3× and 3× using `UIScrollView`.
- **Tiled rendering:** `CATiledLayer` and Core Graphics draw grid lines and pieces for each requested tile. Tile rendering looks up cells in its own region, and a lock protects the render snapshot from concurrent updates.
- **Move feedback:** animated placement rings, highlighted winning cells, a result dialog, turn indicators, and session scores.
- **Local history:** completed matches store their UUID, completion date, winner, and total moves using `Codable` JSON in `UserDefaults`. The history screen displays the newest 100 records and supports clearing them.

## Run the app

1. Clone this repository:

   ```sh
   git clone https://github.com/Lyquang/TicTacToe-IOS-App.git
   cd TicTacToe-IOS-App
   open TicTacToe.xcodeproj
   ```

2. Select the **TicTacToe** scheme and an iPhone or iPad simulator.
3. Press **Run** (`⌘R`).

The deployment target is **iOS 14.4**. No third-party dependencies are required. To run on a physical device, select your personal development team and a unique bundle identifier in **Signing & Capabilities**.

## How to play

Tap an empty cell to place the current player's piece. X is red and O is off-white for contrast against the dark board. Connect at least five pieces to win; blocked ends do not invalidate a line. Drag to explore, pinch to zoom, use **Reset** to start another round, and open **History** to inspect completed matches.

Resetting an unfinished round discards it without recording a result. Session scores survive a round reset but restart when the app restarts; completed match summaries remain on the device.

## Architecture

| Layer | Files | Responsibility |
| --- | --- | --- |
| Model | `Models/Coordinate.swift`, `Player.swift`, `MatchRecord.swift` | Hashable coordinates, player identity, Codable match summaries |
| ViewModel | `ViewModels/GameViewModel.swift` | Move validation, turns, win detection, session scores, history persistence |
| View | `Views/GameViewController.swift` | UIKit layout, gestures, callbacks, and result presentation |
| Rendering | `Views/InfiniteBoardView.swift` | Thread-safe render snapshots, tiled Core Graphics drawing, animations |
| History | `Views/HistoryViewController.swift` | Saved summaries and history deletion |

After each valid move, the ViewModel checks **four axes through that move**, scanning contiguous matching pieces in both directions. A gap or opposing piece stops a scan. A winning line is returned in spatial order, the round is marked complete, and exactly one summary is saved before completion callbacks run.

Models and the ViewModel use Foundation; UIKit appearance belongs to the view layer. `GameViewModel` accepts a `UserDefaults` instance so tests use isolated storage instead of a player's real history.

## Tests and build

Run the rules and persistence tests on macOS with Swift 5.9 or later:

```sh
swift test
```

Tests cover both players across all four axes, a move joining both sides of an overline, gaps and blocking pieces, invalid moves, callback state, reset behavior, JSON persistence across ViewModel instances, corrupt data, clearing history, and the 100-record limit.

Build the iOS app for Simulator without signing:

```sh
xcodebuild -project TicTacToe.xcodeproj \
  -scheme TicTacToe \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

## Current scope

- The rules accept arbitrary coordinates, but the UI uses a **6,000 × 6,000 point canvas (125 × 125 cells)**. The existing `InfiniteBoardView` name describes the large-board approach; the viewport does not expand indefinitely.
- Play is local on one device. There is no AI, online multiplayer, or account system.
- History contains summaries, not move-by-move replays or an in-progress game. It stays in this app's local storage and is not synced to a server.
- The draw result remains in the storage model for compatibility. There is currently no draw action or automatic full-board draw detection.
- Tiling reduces off-screen drawing; frame rate has not been benchmarked on physical devices.

## Credits

Original 3×3 project: [CodeWithCal / TicTacToeSwiftXcode](https://github.com/codeWithCal/TicTacToeSwiftXcode). Five-in-a-row adaptation and ongoing development: [Lyquang](https://github.com/Lyquang).
