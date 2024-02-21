import json
import os

def update_json_structure(data):
    for category in data:
        for item in data[category]:
            # Anzahl der Wörter im Satz
            item['Satzlänge'] = len(item['Satz'].split())
            # Anzahl der Buchstaben im Wort
            item['Buchstabenlänge'] = len(item['Wort'])
    return data

def update_json_files(directory_path='S:\\Masterarbeit\\Flutter\\master_app\\assets\\json'):
    # Zähler für bearbeitete Dateien
    files_updated = 0
    
    print(f"Suche nach JSON-Dateien im Verzeichnis: {directory_path}")
    
    # Gehe durch jede Datei im angegebenen Verzeichnis
    for filename in os.listdir(directory_path):
        if filename.endswith(".json"):
            file_path = os.path.join(directory_path, filename)
            
            print(f"Bearbeite Datei: {file_path}")
            
            # Lese die existierende JSON-Datei
            try:
                with open(file_path, 'r', encoding='utf-8') as file:
                    data = json.load(file)
                
                # Aktualisiere die Datenstruktur
                updated_data = update_json_structure(data)
                
                # Schreibe die aktualisierten Daten zurück in die JSON-Datei
                with open(file_path, 'w', encoding='utf-8') as file:
                    json.dump(updated_data, file, ensure_ascii=False, indent=4)
                
                files_updated += 1
            except Exception as e:
                print(f"Fehler beim Bearbeiten von {file_path}: {e}")
    
    print(f"{files_updated} JSON-Datei(en) wurden erfolgreich aktualisiert.")

# Führe die Funktion aus, um die JSON-Dateien im aktuellen Verzeichnis zu aktualisieren
update_json_files()


