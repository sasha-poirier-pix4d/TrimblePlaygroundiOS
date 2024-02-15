# Trimble Playground (iOS)

Playground / Sample / Proving Ground for adding Trimble Catalyst DA2 support into Pix4Dcatch

As Trimble has many differences compared to Vigram or Emlid, namely Trimble account, subscriptions, and licenses management, or using WebSockets to integrate (different tech than other RTK receivers), it was easier to play around with things in a different repo.

Currently this has full WebSocket support, furthur decisions needed if integrate Facade or SDK, which is not recommended.

## WebSocket (finished)
Features
- Receives Location updates from TMM
- Requests the WS port through URL schemes

Everything in the Shareable group can be directly transfered into Catch, and worked into the RTK SDK. Things outside of this folder is mostly SwiftUI for the playground.

## Facade
WND / TBA

## SDK
WND / TBA
