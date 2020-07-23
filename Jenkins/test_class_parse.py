import xml.etree.ElementTree as ET

tree = ET.parse("Jenkins/build.xml")
ET.register_namespace('sf', "antlib:com.salesforce")

root = tree.getroot()
for target in root.iter("target"):
    if target.attrib.get("name") == "deployCode":
        for runLevel in target:
            for elm in list(runLevel):
                # print(elm.tag)
                runLevel.remove(elm)

openfile = open("Jenkins/test-class", 'r')
test_class_list = openfile.readlines()
for target in root.find("target[@name='deployCode']"):
    for class_name in test_class_list:
        run_class = ET.SubElement(target, "runTest")
        run_class.text = class_name.strip()


tree.write("Jenkins/build-1.xml")
