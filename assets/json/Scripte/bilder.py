from openai import OpenAI
import os
import json
import requests
import glob
import shutil  # Importieren der shutil-Bibliothek

client = OpenAI(api_key="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")


def generate_and_save_image(prompt, save_path):
    response = client.images.generate(
      model="dall-e-3",
      prompt=prompt,
      size="1024x1024",
      quality="standard",
      n=1,
    )
    image_url = response.data[0].url
    image_response = requests.get(image_url)
    with open(save_path, 'wb') as file:
        file.write(image_response.content)

# Verzeichnis mit JSON-Dateien
json_directory = 'S:\\Masterarbeit\\Flutter\\master_app\\assets\\json\\'

# Basisverzeichnis, in dem die Bilder gespeichert werden
base_dir_path = 'S:\\Masterarbeit\\Flutter\\master_app\\assets\\Bilder\\'

# Zielverzeichnis für verarbeitete JSON-Dateien
processed_json_directory = 'S:\\Masterarbeit\\Flutter\\master_app\\assets\\json\\Fertig\\'
os.makedirs(processed_json_directory, exist_ok=True) 

json_files = glob.glob(os.path.join(json_directory, '*.json'))

number = 0
for file_path in json_files:
    with open(file_path, 'r', encoding='utf-8') as file:
        data = json.load(file)
    
    for category_name, entries in data.items():
        category_dir = os.path.join(base_dir_path, category_name)
        os.makedirs(category_dir, exist_ok=True)

        for entry in entries:
            prompt = entry.get('Prompt')
            if prompt:
                item_name = entry.get('Wort', f"Unbekannt_{number}")
                save_path = os.path.join(category_dir, f"{item_name}.png")
                generate_and_save_image(prompt, save_path)
                number += 1
                print(f"Bild {number} für {item_name} wurde gespeichert in {category_dir}.")

    # Verschieben der JSON-Datei in den "Fertig"-Ordner, nachdem sie verarbeitet wurde
    destination_path = os.path.join(processed_json_directory, os.path.basename(file_path))
    shutil.move(file_path, destination_path)
    print(f"{os.path.basename(file_path)} wurde nach {destination_path} verschoben.")

print("Alle Bilder wurden erfolgreich generiert und JSON-Dateien verarbeitet.")
