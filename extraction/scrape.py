import requests
from bs4 import BeautifulSoup
import pandas as pd
import re
import unicodedata

BASE_URL = 'https://en.wikipedia.org'


def get_year_range(text):
    """ given a text, format """
    text = text.replace('–', '-')
    text = re.sub(r'\(died \d{4}\)', '', text)
    text = re.findall(r'\d{4}–\d{4}|\d{4}-\d{4}|\d{4}–\bpresent\b|\d{4}-\bpresent\b|\d{4}', text)

    return text


def split_member_info(text):
    years_active = ''.join(re.findall(re.compile('\((\d+[^)]*\d*)\)'), text))
    text = text.replace(years_active, '').split('–')[0].strip()
    return text, years_active


def get_member_from_list(soup):
    print('find from list')

    for h2 in soup.find_all('h2'):
        for search in ['members', 'personnel', 'lineup', 'line-up']:
            if search in h2.text.lower():
                next_tag = h2
                break

    results = []
    while next_tag is not None:
        next_tag = next_tag.next_sibling
        try:
            for item in next_tag.find_all('li'):
                text = unicodedata.normalize('NFKD', item.text)
                if len(re.findall(re.compile('\w* – [\w ]+ \([^)]*\)'), text)) > 0:
                    results.append(text)
        except:
            pass
    df = pd.DataFrame([split_member_info(text) for text in results], columns=['member', 'member years active'])
    df['attr'] = df['member years active'].apply(lambda text: 'current' if 'present' in text else 'past')
    return df


def get_members_from_table(tables):
    print('find from table')

    dfs = []
    for table, attr in zip(tables[0:2], ['current', 'past']):
        table['attr'] = attr
        table = table.rename(columns={'Name': 'member',
                                      'Years active': 'member years active'})
        dfs.append(table)

    return pd.concat(dfs)[['member', 'attr', 'member years active']]


def find_from_table(soup):
    # get infoboxes
    infoboxes = [tag
                 for tag in soup.find_all(class_='infobox-label')
                 if tag.text in ['Members', 'Past members']]

    for infobox in infoboxes:
        for child in infobox.parent.children:
            if 'list' in child.text.lower():
                try:
                    page_url = child.find('a')['href']
                except TypeError:
                    return

                member_table_columns = ['Image', 'Name', 'Years active', 'Instruments', 'Release contributions']

                tables = pd.read_html(BASE_URL + page_url)
                tables = [table for table in tables
                          if table.columns.tolist() == member_table_columns]

                if len(tables) >= 2:
                    members_df = get_members_from_table(tables)

                else:
                    members_df = get_member_from_list(soup)
                members_df['member years active'] = members_df['member years active'].apply(get_year_range)
                return members_df

def get_members(infobox):
    """
    given an infobox, grab the members and past members
    """
    for child in infobox.parent.children:
        if child.text != 'Past members' and child.text != 'Members':
            members = child.get_text(strip=True, separator=", ").split(',')
            members = [text.strip() for text in members]
            return members


def fill_from_infobox(soup, df):
    # get band name
    band = soup.find('h1', class_='firstHeading').text
    df['band'] = band
    df['sections'] = len(soup.find_all('h2'))

    if 'member' in df.columns:
        df['member'] = df['member'].apply(lambda text: re.sub(r'\s\([^)]*\)', '', text))

    try:
        df['years active'] = soup.find('th', class_='infobox-label', string='Years active').parent.find('td').text
        df['years active'] = df['years active'].apply(get_year_range)
        df['breakups'] = df['years active'].apply(len) - 1
    except:
        pass

    try:
        df['origin'] = soup.find('th', class_='infobox-label', string='Origin').parent.find('td').text
    except:
        pass

    return df


def find_from_infobox(soup):
    print('find from infobox')
    # get current members
    members = []
    df = pd.DataFrame()

    infobox = soup.find(class_='infobox-label', string='Members')
    if infobox is not None:
        members = get_members(infobox)
        if members is not None:
            if len(members) > 1:
                df = pd.DataFrame({'member': members,
                                   'attr': 'current'})
            else:
                df = pd.DataFrame({'member': members,
                                   'attr': 'current'}, index=[0])

    # get past members
    infobox = soup.find(class_='infobox-label', string='Past members')
    if infobox is not None:
        past_members = get_members(infobox)
        if past_members is not None:
            if len(past_members) > 1:
                df = df.append(pd.DataFrame({'member': past_members,
                                             'attr': 'past'}))
            else:
                df = df.append(pd.DataFrame({'member': past_members,
                                             'attr': 'past'}, index=[0]))

    return df


def scrape(url):
    """
    given a band wikipedia page, scrape the members and attributes
    and return their info in dataframe
    """
    page = requests.get(url)
    soup = BeautifulSoup(page.content, "html.parser")

    df = find_from_table(soup)
    if df is None:
        df = find_from_infobox(soup)

    df = fill_from_infobox(soup, df)
    return df


if __name__ == '__main__':
    # this band has members in a table
    print(scrape(BASE_URL + '/wiki/Guns_N%27_Roses'))

    # this band has members in a table
    print(scrape(BASE_URL + '/wiki/Megadeth'))

    # this band has membeers in a list
    print(scrape(BASE_URL + '/wiki/Savatage'))

    # this band has membeers listed in the infobox
    print(scrape(BASE_URL + '/wiki/Def_Leppard'))
