from bs4 import BeautifulSoup
from pathlib import Path
import argparse
import requests
import os

CFLOOKUP_URL = "https://cflookup.com/{}"
CFDOWNLOAD_URL = "https://curseforge.com/hytale/mods/{}/download/{}"
CFDOWNLOAD_URL2 = "https://www.curseforge.com/api/v1/mods/{}/files/{}/download"
FORGECDN_URL = "https://mediafilez.forgecdn.net/files/{}/{}/{}"
# forgecdn links break project ids into 4 long parts, e.g.
# 7453942 needs to be converted to 7453/942
# https://mediafilez.forgecdn.net/files/7449/795/Overstacked-2026.1.12-30731.jar

def main():
    parser = argparse.ArgumentParser(description="Hytale Mod Downloader")
    parser.add_argument('--mod-ids', type=str, help='Comma-separated list of mod IDs to download')
    parser.add_argument('--output-dir', type=str, default='mods', help='Directory to save downloaded mods')
    args = parser.parse_args()
    
    Path(args.output_dir).mkdir(exist_ok=True)
    
    
    mod_ids = args.mod_ids.split(',') if args.mod_ids else []
    
    for mod_id in mod_ids:
        url = CFLOOKUP_URL.format(mod_id)
        response = requests.get(url)
        
        if response.status_code == 200:
            soup = BeautifulSoup(response.content, 'html.parser')
            mod_name_soup = soup.find('a', class_='text-white')
            mod_link = mod_name_soup['href']
            mod_name = mod_link.split('/')[-1]
            print(f"Mod Name: {mod_name}")
            print(f"Mod Link: {mod_link}")
            tables = soup.find_all('table', class_='table')
            for table in tables:
                caption = table.find('caption')
                if caption and 'Latest version information' in caption.text:
                    file_table = table
                    break
            latest_release = file_table.find('tbody').find('tr').find_all('td')
            mod_filename = latest_release[0].text.strip()
            print(f"Jar Name: {mod_filename}")
            install_button = latest_release[3].find('div', class_='cf-install-button')
            link = install_button.find('a')
            if link and 'href' in link.attrs:
                fileid = link['href'].split('=')[-1]
                print(f"File ID: {fileid}")
                download_link = FORGECDN_URL.format(fileid[:4], fileid[4:], mod_filename)
                print(f"Download Link: {download_link}")
                mod_download = requests.get(download_link)
                print(f"Mod Download Response Status Code: {mod_download.status_code}")
                if mod_download.status_code == 200:
                    with open(os.path.join(args.output_dir, mod_filename), "wb") as file:
                        file.write(mod_download.content)
                    print(f"Mod downloaded successfully as {mod_filename}")
                
        else:
            print(f"Failed to retrieve the webpage. Status code: {response.status_code}")


if __name__ == "__main__":
    main()
