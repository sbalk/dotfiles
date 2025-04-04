#!/usr/bin/env -S uv run --with pyyaml

import os

import yaml

CONFIG = "install.conf.yaml"

stream = open(CONFIG)
conf = yaml.load(stream, yaml.FullLoader)

for section in conf:
    if "link" in section:
        for target in section["link"]:
            realpath = os.path.expanduser(target)
            if os.path.islink(realpath):
                print("Removing ", realpath)
                os.unlink(realpath)
