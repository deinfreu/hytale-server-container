from bs4 import BeautifulSoup
from pathlib import Path
import argparse
import requests
import os
import logging

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
    parser.add_argument('--output-dir', type=str, default='mods', required=True, help='Directory to save downloaded mods')
    parser.add_argument('--log-level', type=str, default='INFO', help='Set the logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)')
    args = parser.parse_args()
    
    logging.basicConfig(level=getattr(logging, args.log_level.upper(), logging.INFO))
    
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
            logging.info(f"Downloading Mod Name: {mod_name}")
            logging.debug(f"Mod Link: {mod_link}")
            tables = soup.find_all('table', class_='table')
            for table in tables:
                caption = table.find('caption')
                if caption and 'Latest version information' in caption.text:
                    file_table = table
                    break
            latest_release = file_table.find('tbody').find('tr').find_all('td')
            mod_filename = latest_release[0].text.strip()
            logging.debug(f"Jar Name: {mod_filename}")
            install_button = latest_release[3].find('div', class_='cf-install-button')
            link = install_button.find('a')
            if link and 'href' in link.attrs:
                fileid = link['href'].split('=')[-1]
                logging.debug(f"File ID: {fileid}")
                if fileid[4] == '0':
                    logging.debug("File ID has a zero at position 5, adjusting...")
                    fileid = fileid[:4] + fileid[5:]
                    logging.debug(f"Adjusted File ID: {fileid}")
                download_link = FORGECDN_URL.format(fileid[:4], fileid[4:], mod_filename)
                logging.debug(f"Download Link: {download_link}")
                mod_download = requests.get(download_link)
                logging.debug(f"Mod Download Response Status Code: {mod_download.status_code}")
                if mod_download.status_code == 200:
                    with open(os.path.join(args.output_dir, mod_filename), "wb") as file:
                        file.write(mod_download.content)
                    logging.info(f"Mod downloaded successfully as {mod_filename}")
                
        else:
            logging.error(f"Failed to retrieve the webpage. Status code: {response.status_code}")


if __name__ == "__main__":
    main()
