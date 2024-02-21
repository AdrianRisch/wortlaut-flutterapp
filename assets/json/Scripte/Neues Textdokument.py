import json

# Pfad zur Eingabedatei
input_datei = 'assets\json\zusammengefasste_daten.json'
# Pfad zur Ausgabedatei
output_datei = 'geaenderte_daten.json'

# Funktion zum Ersetzen von Sonderzeichen
def ersetze_sonderzeichen(wort):
    ersetzung = {
        'ä': 'ae',
        'ö': 'oe',
        'ü': 'ue',
        'ß': 'ss',
        'Ä': 'Ae',
        'Ö': 'Oe',
        'Ü': 'Ue',
    }
    for original, ersatz in ersetzung.items():
        wort = wort.replace(original, ersatz)
    return wort

# Einlesen der JSON-Daten
with open(input_datei, 'r', encoding='utf-8') as file:
    daten = json.load(file)

# Ersetzen der Sonderzeichen in den Wörtern
geaenderte_daten = []
for element in daten:
    if 'Wort' in element:
        element['Wort'] = ersetze_sonderzeichen(element['Wort'])
    geaenderte_daten.append(element)

# Schreiben der geänderten Daten in eine neue Datei
with open(output_datei, 'w', encoding='utf-8') as file:
    json.dump(geaenderte_daten, file, ensure_ascii=False, indent=4)

print('Die Datei wurde erfolgreich bearbeitet und gespeichert als', output_datei)
