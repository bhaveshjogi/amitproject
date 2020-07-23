import json
import os

os.listdir()
print(os.listdir())
tem_target = {"path": "target", "default": False}
with open("./sfdx-project.json", "r") as jsonFile:
    data = json.load(jsonFile)

data['packageDirectories'].append(tem_target)

with open("./sfdx-project.json", "w") as jsonFile:
    json.dump(data, jsonFile, indent=2)
