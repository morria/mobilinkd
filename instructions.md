# Instructions
Each of the following points **must** be adhered to when discussing or editing code in this repo.

## Purpose
The purpose of this code is to enable interaction with a "Mobilinkd TNC4" device to both send and receive messages.

The Mobilinkd TNC4 device is interacted with via Bluetooth Low Energy (BLE). Data received from it is encoded in a stack of three protocols.

- Layer 1: KISS
- Layer 2: AX.25
- Layer 3: APRS

The KISS protocol is described in the file [docs/KISS Protocol.pdf](docs/KISS%20Protocol.pdf).
The AX.25 protocol is described in the file [docs/AX25.2.2-Jul 98-2.pdf](docs/AX25.2.2-Jul%2098-2.pdf).
The APRS protocol is described in the file [docs/APRS101.pdf](docs/APRS101.pdf).

## Code
All code is in Swiftlang version 6.

All tests are in the [./Tests](./Tests) directory and all application code is in [./Sources](./Sources). The file [./Package.swift](./Package.swift) indicates which directories are used in which contexts.

See [Sources/aprs/main.swift](Sources/aprs/main.swift) for usage.


## Testing.
This project uses Swift Testing, not XCTest. All tests should use Swift Testing via `@import Testing` and via macro `#expect()` tests.

## Data
Data is sent and received from the TNC device as `[UInt8]` and should only be encode as UTF8 `String` data at the APRS layer.

## Style
Code should prefer readability over brevity. Code should use common Swift idioms so as to be readily understood by those who work with Swift and the iOS/macOS ecosystem.

