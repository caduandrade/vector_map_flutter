## 0.6.1

* Bugfix mobile
  * Wrong feature on click listener

## 0.6.0

* Pan and zoom mode
* Placeholder for map without layers
* `MapDataSource.geoJSON` renamed to `MapDataSource.geoJson`
* `contourThickness` parameter moved from `VectorMap` to `VectorMapController`
* `VectorMapController.getLayer` renamed to `VectorMapController.getLayerByIndex`
* New methods
  * `VectorMapController.getLayerById`
  * `VectorMapController.hasLayerId`

## 0.5.0

* Gradient legend
* `MapLayer.hoverTheme` refactored to `MapLayer.highlightTheme` to be used by addons as well

## 0.4.0

* Debugger
* GeoJSON line geometry reader
  * It remains to calculate buffered area to allow the hover to be detected
* Experimental (the API will change)
  * Addons
    * Gradient legend

## 0.3.0

* Drastic reduction in package size
  * Demo moved to separate repository
* Marker

## 0.2.0

* Multiple layers
* GeoJSON point geometry reader

## 0.1.0

* Initial release
