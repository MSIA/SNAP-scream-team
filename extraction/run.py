import time
from scrape import *
import os

BASE_URL = 'https://en.wikipedia.org'


def run_early_bands():

    # ## Scrape early bands
    # A more manageable dataset

    url = BASE_URL + '/wiki/List_of_heavy_metal_bands'
    page = requests.get(url)
    soup = BeautifulSoup(page.content, "html.parser")
    table = soup.find_all('tbody')[1]

    partial_links = [a['href'] for a in table.find_all('a')]
    band_links = [link for link in partial_links if link.startswith('/wiki')]

    df_list = []

    for link in band_links:
        print(link)
        url = BASE_URL + link
        df_list.append(scrape(url))

    early = pd.concat([item for item in df_list if type(item) != str])
    print(len(early))
    early.to_csv('early_bands_11_27.csv', index=False)

def get_partial_links(soup):
    """
    given beautiful soup messy output, extract the links (starting with '/wiki/')
    """
    print(f'getting partial links from raw list of {len(soup)}')
    partial_links = []
    for tag in soup:
        try:
            atag = tag.find('a')
            if atag is not None:
                link = atag['href']
                if link.startswith('/wiki') and ':' not in link:
                    partial_links.append(link)
        except KeyError:
            continue
    return partial_links


def get_band_lists(genre_url):
    url = BASE_URL + genre_url
    print(url)
    page = requests.get(url)
    soup = BeautifulSoup(page.content, "html.parser")

    bands_table = soup.find_all('table', class_='wikitable')
    if len(bands_table) == 0:
        bands_list = soup.find_all('li')
    else:
        bands_list = []
        for table in bands_table:
            for row in table.tbody.findAll('tr'):
                try:
                    bands_list.append(row.find('td').find('a')['href'])
                except:
                    continue
    return bands_list


def run_subgenres():
    # ## Scrape bands from all sub genres
    # This takes a long time

    ## get list of other sub-genres
    url = BASE_URL + '/wiki/List_of_heavy_metal_bands'
    page = requests.get(url)
    soup = BeautifulSoup(page.content, "html.parser")
    genres_list = soup.find_all('ul')[0].find_all('li')

    genre_links = get_partial_links(genres_list)
    genre_links = [link for link in genre_links if link.startswith('/wiki/List_of')]

    sub_genres = []
    for genre_url in genre_links:
        print(genre_url)
        page = requests.get(BASE_URL + genre_url)
        soup = BeautifulSoup(page.content, "html.parser")
        bands_table = soup.find_all('table', class_='wikitable')
        if len(bands_table) == 0:
            bands_list = soup.find_all('li')
            bands_list = get_partial_links(bands_list)
        else:
            bands_list = []
            for table in bands_table:
                for row in table.tbody.findAll('tr'):
                    try:
                        bands_list.append(row.find('td').find('a')['href'])
                    except:
                        continue
        sub_genres.append(bands_list)
    for genre, band_list in zip(genre_links, sub_genres):
        filename = genre.replace('/wiki/List_of', '')
        pd.DataFrame({'bands': band_list}).to_csv(filename, index=False)


def run_bands_per_genre(band_list):
    df_list = []
    for url in band_list:
        df = scrape(BASE_URL + url)
        print(f'adding {len(df)} members for {url}')
        df_list.append(df)
    time.sleep(3)

    return pd.concat(df_list)


if __name__ == '__main__':
    # run_early_bands()
    print(os.listdir('../genres/'))
    for file in os.listdir('../genres/')[11:]:
        print('-------------------')
        print(file)
        band_list = pd.read_csv('../genres/' + file)
        df = run_bands_per_genre(band_list['bands'].values)
        df['genre'] = file
        df.to_csv(f'../data/{file}.csv', index=False)
        print('-------------------')
