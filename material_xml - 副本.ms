--Load the xml assembly
 dotNet.loadAssembly "system.xml"
 --Create an xml document object.
 xmlDoc = dotNetObject "system.xml.xmlDocument"
 
-- showMethods xmlDoc
-- Create a root element for the xml doc and add it to the xmlDocument.
root = xmlDoc.createElement "RedHalo_Max_to_Blender_Covert"

xmlDoc.appendChild root

NodeListElement = xmlDoc.createElement "NodeList"
root.appendChild NodeListElement

CameraListElement = xmlDoc.createElement "CameraList"
root.appendChild CameraListElement

LightListElement = xmlDoc.createElement "LightList"
root.appendChild LightListElement

MaterialList = xmlDoc.createElement "MaterialList"
root.appendChild MaterialList

MaterialItemList = xmlDoc.createElement "MaterialItem"
root.appendChild MaterialItemList

-- Global Vars-----
Material_List = #()

-- Object List
for i in objects do (
    name = i.name
    
    visible_camera = i.primaryVisibility
    visible_reflect = i.secondaryVisibility
    visible_refract = i.secondaryVisibility
    visible_shadow = i.castShadows
    
    objectList = xmlDoc.createElement "Node"
    objectList.setAttribute "name" name
    objectList.setAttribute "visible_camera" "1"
    objectList.setAttribute "visible_refect" "1"
    objectList.setAttribute "visible_refract" "1"
    objectList.setAttribute "visible_shadow" "1"

    NodeListElement.appendChild objectList
)

-- Camera List
cams = for i in cameras where classof i == Targetcamera or classof i == FreeCamera or classof i == VRayPhysicalCamera or classof i == CoronaCam collect i

for i in cams do (
    name = i.name
    fov = i.fov as string

    cameraList = xmlDoc.createElement "camera"
    cameraList.setAttribute "name" name
    cameraList.setAttribute "fov" fov

    CameraListElement.appendChild cameraList
)

-- Light List
for i in lights do (
    name = i.name

    lightNode = xmlDoc.createElement "light"
    lightNode.setAttribute "type" "point"
    lightNode.setAttribute "ammount" "10"

    LightListElement.appendChild lightNode
)
-- materials = for i in sceneMaterials


fn GetAllMaterials material = (
    type = classof material

    case type of (
        MultiMaterial:(
            for m = 1 to material.numsubs do(
                GetAllMaterials material[m]
            )
        )
        VRay2SidedMtl:(
            if material.frontMtl != undefined do GetAllMaterials material.frontMtl
            if material.backMtl != undefined do GetAllMaterials material.backMtl
        )
        default:(
            append Material_List material
        )
    )
)


-- Material type
fn CreateType mat  = (
    liststring = #()
    type = classof mat
    name = ""
    matType = ""
    case type of (
        MultiMaterial:(
            for m in mat.materialList do(
                type = ClassOf m
                append liststring m.name
            )
        )
        VRay2SidedMtl:(
            append liststring mat.frontMtl.name
            append liststring mat.backMtl.name
        )
        default:(
            name = mat.name
            append liststring name
        )
    )

    ss = ""
    for i = 1 to liststring.count do (
        ss += liststring[i]
        if i < liststring.count do ss += ","
    )

    materialNode = xmlDoc.createElement "PBRMaterial"
    materialNode.setAttribute "name" name
    materialNode.setAttribute "type" (type as string)
    materialNode.setAttribute "ListString" (liststring as string)

    MaterialList.appendChild materialNode
)

materials = #()
-- Material type
for i in sceneMaterials do (
    CreateType i
)

fn appendDiffuse parent = (
    diffuseNode = xmlDoc.createElement "Diffuse"
    diffuseNode.setAttribute "color" "(1,1,1,1)"

    parent.appendChild diffuseNode
)

-- List All Material, include submat
for i in sceneMaterials do (
    name = i.name
    type = classof i as string

    pbrMaterialItemNode = xmlDoc.createElement "PBRMaterial"
    pbrMaterialItemNode.setAttribute "name" name
    pbrMaterialItemNode.setAttribute "type" type
    
    
    MaterialItemList.appendChild pbrMaterialItemNode

    appendDiffuse pbrMaterialItemNode

    GetAllMaterials i
)

xmlDoc.Save "D:\\xml_Temp.xml"

print "--------------------------------------------"
print Material_List
print "--------------------------------------------"