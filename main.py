#!/usr/bin/env python3

from urllib.error import ContentTooShortError
from urllib.request import urlretrieve
from dataclasses import dataclass
from bs4 import BeautifulSoup
from zipfile import ZipFile
from git import Repo
import requests
import json
import re
import os

MAX_RETRIES = 5
def download(url, file):
    retry = 0
    while retry < MAX_RETRIES:
        try:
            urlretrieve(url, file)
            break
        except ContentTooShortError:
            print("Connection interrupted, retrying...")
            retry += 1

@dataclass
class Tool:
    url: str
    version: str

repo_path = os.path.dirname(os.path.realpath(__file__))
os.chdir(repo_path)

repo = Repo(repo_path)

assert not repo.bare
assert not repo.is_dirty(untracked_files = True)

master = repo.heads[0]
origin = repo.remote()
assert "renoise-tools-mirror" in origin.url

print(f"Getting tools list...")

TOOL_RE = re.compile("/uploads/tools/.+")

RENOISE_URL = "https://www.renoise.com"
tools_page = requests.get(RENOISE_URL + "/tools")
tools_soup = BeautifulSoup(tools_page.text, "html.parser")

tool_page_attrs = {"phx-click": re.compile(".+/tools/.+")}
tool_page_hrefs = tools_soup.find_all(attrs = tool_page_attrs)
get_tool_page_href = lambda x: json.loads(x["phx-click"])[0][1]["href"]
tool_page_hrefs = set(map(get_tool_page_href, tool_page_hrefs))

tool_page_urls = [RENOISE_URL + href for href in tool_page_hrefs]

print(f"Got {len(tool_page_urls)} tools!")

tools = []
for tool_page_url in tool_page_urls:
    print(f"Parsing {tool_page_url}...")
    tool_page = requests.get(tool_page_url)
    tool_page_soup = BeautifulSoup(tool_page.text, "html.parser")

    tool_elem = tool_page_soup.find_all("a", href=TOOL_RE)[-1]

    tool_url = RENOISE_URL + tool_elem["href"]
    tool_version = tool_elem.button.text.strip().split(" ")[0]
    tools.append(Tool(tool_url, tool_version))

for tool in tools:
    tool_file = tool.url.split("/")[-1]
    tool_id = tool_file.split("_")[0]
    print(f"> {tool_id} ({tool.version})...")

    if tool_id in repo.branches:
        repo.heads[tool_id].checkout()
    else:
        repo.git.switch(orphan=tool_id)

    download(tool.url, tool_file)

    with ZipFile(tool_file) as f:
        f.extractall()
    os.remove(tool_file)

    repo.index.add("*")
    repo.index.commit(tool.version)

    master.checkout()

origin.push()
