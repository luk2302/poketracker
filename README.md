# PokeTracker

Einfaches iOS-Projekt, um Pokemons zu tracken, sofern eine Map wie https://www.pokemapmuc.de/ lokal vorhanden ist.
Ziel ist es, eine Möglichkeit zu haben, die erreichbaren Pokemons in direkter Umgebung zu sehen. Man sieht explizit nicht genau wo diese sind. Man soll weiterhin versuchen, ein Pokemon selber aufzuspüren.

![](https://i.imgur.com/qL4UF1ol.png)
![](https://i.imgur.com/f2BPlVtl.png)

## Features

* Übersicht über die Pokemons in deiner Nähe
  * mit grober Distanz-Anzeige
  * mit grober Anzeige der Zeit bis zum Despawn
* Ein trackbares Pokemon (auf ein Pokemon lang drücken)
  * grüner Hintergrund bedeutet dass man grob in die richtige Richtung schaut, dann einfach weiter in die Richtung laufen. Oder Handy ein bisschen drehen um die Richtung einzuschränken
* Doppel-Touch entfernt ein Pokemon aus der Liste
* Pokemons filterbar durch Touch auf ein Pokemon in den "Settings", bspw. Taubsi und Co
* Übersicht über die Gyms in der Nähe
  * Team-Farbe + Level
  * Anstehende oder laufende Raids

## Wie nutze ich diese App?

* Cocoapods installieren
* Xcode installieren
* Repo klonen
* Im Terminal ins Repo wechseln und ```pod install``` ausführen
* ```PokeTracker.xcworkspace``` in Xcode öffnen
* In Xcode das Projekt bauen und auf ein iPhone deployen

## FAQ
* Wieso gibt's die App nicht im AppStore? 
  * Weil ich mir die Mühe nicht machen wollte. Ich denke, dass ich dann mich mehr um Lizenzen und so weiter kümmern müsste. Wenn genug Interesse besteht lass ich mich vielleicht umstimmen
* Mir werden keine Pokemon und Gyms angezeigt! 
  * Bitte einmal checken, ob die zugrundeliegende Map, also bspw. pokemapmuc gerade, gerade nicht erreichbar ist. Gerne mich kontaktieren falls die Map funktioniert, die App allerdings nicht

- - - -
  
### Disclaimer
Dies ist ein reines Spaß-Projekt. Ich habe keinen besonderen Wert auf schönen Code gelegt, der ist eher ... gewachsen. Es gibt keine Tests, die Swift-Version ist nicht aktuell, das Design ist nicht schön, an einigen Stellen nicht force-unwraps eingebaut. Insbesondere wenn sich an der Map / Datenquelle etwas ändert ist es durchaus wahrscheinlich, dass die App crasht.
