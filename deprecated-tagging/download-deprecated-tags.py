#!/usr/bin/python3

import requests, json, re
from urllib.request import urlopen
from urllib.parse import unquote
from bs4 import BeautifulSoup

wiki_base = "https://wiki.openstreetmap.org"
response = requests.get("https://wiki.openstreetmap.org/w/index.php?title=Special:WhatLinksHere/Template:PossibleSynonym&limit=5000")

page_list = []
deprecated_taginfo = []
deprecated_taginfo_k = []
deprecated_taginfo_t = []

key_count_map = {}
tag_count_map = {}

synonym_soup = BeautifulSoup(response.text, 'html.parser')
links = synonym_soup.find("ul", {"id": "mw-whatlinkshere-list"}).find_all("li")
for link in links:
  a = link.find("a");
  page_list.append(a['href']);

print("Inspecting ", len(page_list), " pages")

page_count = 0

for page_url in page_list:
  key_page = wiki_base + page_url;
  key_load = requests.get(key_page);
  tag_soup = BeautifulSoup(key_load.text, 'html.parser')

  synonym_boxes = tag_soup.find_all("div", {"class", "possible_synonym"})

  for synonym_box in synonym_boxes:
    synonym_taginfo_frame = synonym_box.find("iframe");

    if synonym_taginfo_frame is not None:
      synonym_taginfo_url = synonym_taginfo_frame["src"];
      deprecated_taginfo.append(synonym_taginfo_url);

  page_count += 1
  print("[", page_count, "]", page_url);

deprecated_taginfo_nodupe = list(set(deprecated_taginfo))
for taginfo in deprecated_taginfo_nodupe:
  if "taginfo.openstreetmap.org/embed/tag?" in taginfo:
    deprecated_taginfo_t.append(taginfo.replace("//taginfo.openstreetmap.org/embed/tag?", "https://taginfo.openstreetmap.org/api/4/tag/stats?"))
  elif "taginfo.openstreetmap.org/embed/key?" in taginfo:
    deprecated_taginfo_k.append(taginfo.replace("//taginfo.openstreetmap.org/embed/key?key=", "https://taginfo.openstreetmap.org/api/4/key/stats?key="))

count=0

print("Inspecting ", str(len(deprecated_taginfo_k)), "keys")
print("Inspecting ", str(len(deprecated_taginfo_t)), "tags")

kcount=0
tcount=0

for taginfo in deprecated_taginfo_k:
  m = re.match(".*key=(.*)", taginfo)
  if m:
    key = unquote(m.group(1))
    tcount += 1
    print("K> (", str(tcount), ") ", key)

    with urlopen(taginfo) as url:
      stats = json.loads(url.read().decode())
      data = stats["data"]
      count_all = data[0]["count"];
      count += count_all
      key_count_map[key] = count_all

for taginfo in deprecated_taginfo_t:
  m = re.match(".*key=(.*)&value=(.*)", taginfo)
  if m:
    key = unquote(m.group(1))
    val = unquote(m.group(2))
    tag = key + "=" + val
    kcount += 1
    print("T> (", str(kcount), ") ", tag)

    with urlopen(taginfo) as url:
      stats = json.loads(url.read().decode())
      data = stats["data"]
      count_all = data[0]["count"];
      count += count_all
      tag_count_map[tag] = count_all

with open('deprecated_tags.csv', 'w') as csv:

  for key, value in key_count_map.items():
    csv.write(key + "," + str(value) + "\n")

  for key, value in tag_count_map.items():
    csv.write(key + "," + str(value) + "\n")


print("Total possible synonyms: " + str(count))
