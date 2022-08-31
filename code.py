# fbxname = "FBXASC231FBXASC170FBXASC151FBXASC229FBXASC184FBXASC152"
# names = [chr(int(i)) for i in fbxname.split("FBXASC")[1:]]
# s = "".join(names)
# print(s.encode("iso-8859-1").decode("utf-8"))

from re import X
from xml.etree import ElementTree as xml
import os

xmlfile = "D:\\xml_Temp.xml"
xml_file = xml.parse(xmlfile)
xml_root = xml_file.getroot()

# material_name = "Mat3d66_1685556_67_5188"
# m = xml_root.find("./MaterialList/*/[@name='%s']" % material_name)

objects_list = xml_root.find("./ObjectList")

# for obj in objects_list.findall("./*") :    
    # c = True if obj.attrib["Render"] == "true" else False
    # print(c)

l = 1
fac = 0.001
a = 0.005 if l * fac < 0.005 else l * fac
print(a)
