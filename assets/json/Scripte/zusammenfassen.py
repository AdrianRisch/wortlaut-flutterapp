import os
import json

# Pfad zum Ordner mit den JSON-Dateien
ordner_pfad = 'S:\\Masterarbeit\\Flutter\\master_app\\assets\\json\\'

# Liste für das zusammengefasste Ergebnis
zusammengefasste_daten = []

# Durchlaufe alle Dateien im angegebenen Ordner
for dateiname in os.listdir(ordner_pfad):
    if dateiname.endswith('.json'):
        # Vollständiger Pfad zur Datei
        voller_pfad = os.path.join(ordner_pfad, dateiname)
        
        # Lade die JSON-Daten aus der Datei
        with open(voller_pfad, 'r', encoding='utf-8') as datei:
            daten = json.load(datei)
            
            # Gehe davon aus, dass jede Datei genau einen Schlüssel (Kategorienamen) enthält
            for kategorie_name, objekte in daten.items():
                # Füge die Kategorie zu jedem Objekt hinzu und sammle die Daten
                for objekt in objekte:
                    objekt['Kategorie'] = kategorie_name
                    zusammengefasste_daten.append(objekt)

# Zusammengefasste Daten sind jetzt bereit für die weitere Verwendung
# Speicherort und Dateiname für die zusammengefasste JSON-Datei
speicherort = 'S:\\Masterarbeit\\Flutter\\master_app\\assets\\json\\zusammengefasste_daten.json'

# Speichere die zusammengefassten Daten in einer neuen JSON-Datei
with open(speicherort, 'w', encoding='utf-8') as datei:
    json.dump(zusammengefasste_daten, datei, ensure_ascii=False, indent=4)

print(f"Die zusammengefassten Daten wurden in '{speicherort}' gespeichert.")