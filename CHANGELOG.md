# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.1.11](https://github.com/livebook-dev/kino_maplibre/tree/v0.1.11) (2024-01-17)

### Added

* Geolocate control via `add_locate_control/2` ([#64](https://github.com/livebook-dev/kino_maplibre/pull/64))
* Terrain control via `add_terrain_control/1` ([#68](https://github.com/livebook-dev/kino_maplibre/pull/68))
* Geocode control via `add_geocode_control/1` ([#69](https://github.com/livebook-dev/kino_maplibre/pull/69))
* Fullscreen control via `add_fullscreen_control/1` ([#71](https://github.com/livebook-dev/kino_maplibre/pull/71))
* Scale control via `add_scale_control/2` ([#73](https://github.com/livebook-dev/kino_maplibre/pull/73))
* Export map via `add_export_map/2` ([#74](https://github.com/livebook-dev/kino_maplibre/pull/74))

## [v0.1.10](https://github.com/livebook-dev/kino_maplibre/tree/v0.1.10) (2023-09-25)

### Fixed

* Fix `Kino` export deprecations ([#61](https://github.com/livebook-dev/kino_maplibre/pull/61))

## [v0.1.9](https://github.com/livebook-dev/kino_maplibre/tree/v0.1.9) (2023-09-05)

### Changed

* Updated to Maplibre v3 - ([#56](https://github.com/livebook-dev/kino_maplibre/pull/56))
* Supports external Maptiler keys - ([#58](https://github.com/livebook-dev/kino_maplibre/pull/58))

## [v0.1.8](https://github.com/livebook-dev/kino_maplibre/tree/v0.1.8) (2023-03-17)

### Added

* MapCell - move and toggle layers ([#52](https://github.com/livebook-dev/kino_maplibre/pull/52))

## [v0.1.7](https://github.com/livebook-dev/kino_maplibre/tree/v0.1.7) (2022-12-05)

### Changed

* Improved geocode integration ([#47](https://github.com/livebook-dev/kino_maplibre/pull/47))
* Relaxed requirement on Kino to `~> 0.7`

## [v0.1.6](https://github.com/livebook-dev/kino_maplibre/tree/v0.1.6) (2022-11-18)

### Added

* Fit bounds ([#45](https://github.com/livebook-dev/kino_maplibre/pull/45))

### Changed

* MapCell source options are now pre-filled ([#44](https://github.com/livebook-dev/kino_maplibre/pull/44))
* MapCell layer IDs are now automatically generated ([#43](https://github.com/livebook-dev/kino_maplibre/pull/43))

### Fixed

* Handles `jump_to` correctly ([#46](https://github.com/livebook-dev/kino_maplibre/pull/46))

## [v0.1.5](https://github.com/livebook-dev/kino_maplibre/tree/v0.1.5) (2022-11-03)

### Added

* Geocoding source for MapCell ([#42](https://github.com/livebook-dev/kino_maplibre/pull/42))
* Geocoding center for MapCell ([#41](https://github.com/livebook-dev/kino_maplibre/pull/41))

## [v0.1.4](https://github.com/livebook-dev/kino_maplibre/tree/v0.1.4) (2022-10-10)

### Changed

* Update Kino requirement ([#37](https://github.com/livebook-dev/kino_maplibre/pull/37))

## [v0.1.3](https://github.com/livebook-dev/kino_maplibre/tree/v0.1.3) (2022-07-31)

### Changed

* Bump `maplibre`

## [v0.1.2](https://github.com/livebook-dev/kino_maplibre/tree/v0.1.2) (2022-07-13)

### Fixed

* Normalizes MapCell attributes to be backwards compatible ([#34](https://github.com/livebook-dev/kino_maplibre/pull/34))

## [v0.1.1](https://github.com/livebook-dev/kino_maplibre/tree/v0.1.1) (2022-07-11)

### Added

* Support for TopoJSON ([#28](https://github.com/livebook-dev/kino_maplibre/pull/28))
* Cluster for Map cell ([#29](https://github.com/livebook-dev/kino_maplibre/pull/29))

### Fixed

* Does not generate invalid symbol layers ([#32](https://github.com/livebook-dev/kino_maplibre/pull/32))

## [v0.1.0](https://github.com/livebook-dev/kino_maplibre/tree/v0.1.0) (2022-06-29)

Initial release.
