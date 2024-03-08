#!/usr/bin/python3
# -*- coding: UTF-8 -*-
from tinyscript import *


CATEGORIES = ("bundler", "compressor", "cryptor", "encoder", "mutator", "protector", "virtualizer")
LABELS = ts.Path("packed/README.md")
SOURCE = ts.Path("packed")

fmt = lambda p: re.sub(r"[-_]", "", p.lower())


def parse_labels():
    packers, start = {}, False
    for line in LABELS.read_lines():
        if not start:
            if line.startswith(b"---"):
                start = True
            continue
        packer, categories = line.decode().split("|")
        for category in categories.split(","):
            category = category.strip()
            packers.setdefault(category, [])
            packers[category].append(fmt(packer))
    return packers


if __name__ == '__main__':
    initialize()
    for category, packers in parse_labels().items():
        if category not in CATEGORIES:
            continue
        logger.info(f"Processing category '{category}'...")
        labels = {}
        for path in SOURCE.walk(filter_func=ts.is_file):
            labels[hashlib.sha256_file(path)] = [None, category][fmt(path.parts[1]) in packers]
        logger.debug("Saving to JSON...")
        with ts.Path(f"labels-{category}.json").open('w') as f:
            json.dump(labels, f, indent=4)

