import json

with open("Profiles.json") as f:
    data = json.load(f)

name = "MyTerminal"

index, mine = next((i, p) for i, p in enumerate(data["Profiles"]) if p["Name"] == name)
default = next(p for p in data["Profiles"] if p["Name"] == "Standards")


def rm_defaults(mine, default):
    to_pop = []
    for k, v in mine.items():
        if k not in default or default[k] != v:
            pass  # leave in
        else:
            to_pop.append(k)
    for k in to_pop:
        mine.pop(k)


rm_defaults(mine, default)

with open("Profiles.json", "w") as f:
    json.dump(data, f, indent="  ")
