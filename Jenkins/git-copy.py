import sys
import subprocess
import glob
import json
import os
import shutil
from pathlib import Path


workingdir = Path("./")
last_two_commits = subprocess.run(
    ["git", "log", "-n2", "--format=format:" "%H"], cwd=workingdir, stdout=subprocess.PIPE, universal_newlines=True)

commit = str(last_two_commits.stdout).splitlines()
last_commit = commit[0]
print(sys.argv)
if len(sys.argv) > 1 and sys.argv[1] != "null":
    previous_commit = sys.argv[1]
else:
    previous_commit = None

if previous_commit != None:
    git_diff = subprocess.run(["git", "diff-tree", "--no-commit-id",
                               "--name-only", "-r", previous_commit, last_commit], cwd=workingdir, stdout=subprocess.PIPE, universal_newlines=True)
    changed_files = str(git_diff.stdout).splitlines()
    print("Total Changed Files: ", len(changed_files))
    if len(changed_files) != 0:
        for item_chnaged in changed_files:
            print("File Changed", item_chnaged)
            if((("lwc" in item_chnaged) or ("aura" in item_chnaged))):
                src_path = Path(item_chnaged)
                parts = list(src_path.parts)
                parts[0] = "target"
                tareg_path = Path(*parts)
                if(not os.path.exists(tareg_path.parent)):
                    shutil.copytree(src_path.parent, tareg_path.parent)
            elif (("force-app" in item_chnaged) and (("lwc" not in item_chnaged) and ("aura" not in item_chnaged))):
                src_file = Path(item_chnaged)
                parts = list(src_file.parts)
                parts[0] = "target"
                target_file = Path(*parts)
                if not os.path.exists(target_file.parent):
                    os.makedirs(target_file.parent)
                    files_list = src_file.parent.rglob(src_file.stem+'.*')
                    for filename in files_list:
                        target_file = target_file.with_name(filename.name)
                        shutil.copy(filename, target_file)
                else:
                    files_list = src_file.parent.rglob(src_file.stem+'.*')
                    for filename in files_list:
                        shutil.copy(filename, target_file)
    else:
        print("Nothing to Copy")
else:
    print("Copying Everything")
    if os.path.exists("target"):
        shutil.rmtree("target")

    shutil.copytree("force-app", "target")

# Add Path in sfdx-project.json
tem_target = {"path": "target", "default": False}

with open("sfdx-project.json", "r") as jsonFile:
    data = json.load(jsonFile)

data['packageDirectories'].append(tem_target)

with open("sfdx-project.json", "w") as jsonFile:
    json.dump(data, jsonFile, indent=2)
