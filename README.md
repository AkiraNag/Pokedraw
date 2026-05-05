# PokéDraw

A personal iOS app to track my Pokémon drawing challenge — draw all 1,214 Pokémon (including alternate forms) one by one.

## Motivation

I wanted a dedicated tool to manage a long-term art challenge: drawing every single Pokémon from the National Dex. The app removes friction by handling the randomization and keeping a visual record of my progress.

## Features

- **Randomizer** — draws a random Pokémon (1–1,214, including alternate forms like Mega Evolutions, regional variants, etc.)
- **Up to 4 draws per session** — re-roll up to 3 times, then choose which one you want to draw from your history
- **Shiny chance** — 1 in 8 probability of getting the shiny version
- **Photo upload** — attach a photo of your finished drawing directly to each entry
- **Normal & Shiny galleries** — two separate 1,214-slot grids tracking completion for each variant
- **Filters** — toggle between all Pokémon and drawn-only views
- **Tap to add / long press to delete** — manage drawings directly from the gallery

## Stack

- SwiftUI
- `@Observable` (iOS 17+)
- PhotosUI
- Local persistence via JSON + JPEG files in the app's Documents directory

## Status

Personal project, actively in development.
