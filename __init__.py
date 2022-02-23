bl_info = {  
    "name": "REDHALO_IMPORT_MTL",  
    "author": "Red Halo Studio",  
    "version": (0, 2),  
    "blender": (2, 80, 0),  
    "location": "View 3D > Tools > Red Halo Tools",  
    "description": "导入3ds Max材质",  
    "wiki_url": "",  
    "tracker_url": "",  
    "category": "Tools"
 }

from math import pi, radians
import bpy
import bpy_extras
from bpy.types import Operator 
import colorsys
import tempfile
import os
from mathutils import Matrix
from xml.etree import ElementTree as xml
from winreg import *

def FixDaeName(string):
    # fbxname = "FBXASC231FBXASC170FBXASC151FBXASC229FBXASC184FBXASC152"
    names = [chr(int(i)) for i in string.split("FBXASC")[1:]]
    str = "".join(names)
    return str.encode("iso-8859-1").decode("utf-8")

def getImportPath():
    # Reg Name in Windows
    RegRoot = ConnectRegistry(None, HKEY_CURRENT_USER)
    RegSubDir = "SOFTWARE\\REDHALO"

    try:
        RegKey = OpenKey(RegRoot, RegSubDir)
        keyName = EnumValue(RegKey, 0)
        return keyName[1]  
    except:
        return ""          

def Create_ColorCorrection():
    # Color Correction Node
    CC_group = bpy.data.node_groups.new('ColorCorrection_RH', 'ShaderNodeTree')
    group_inputs = CC_group.nodes.new('NodeGroupInput')
    group_inputs.location = (0, 0)
    CC_group.inputs.new('NodeSocketColor','Color')
    CC_group.inputs.new('NodeSocketFloat','Bright')
    CC_group.inputs.new('NodeSocketFloat','Contrast')
    CC_group.inputs.new('NodeSocketFloat','Hue')
    CC_group.inputs.new('NodeSocketFloat','Saturation')
    CC_group.inputs.new('NodeSocketFloat','Invert')
    CC_group.inputs.new('NodeSocketFloat','Gamma')

    CC_group.inputs["Color"].default_value = (1,1,1,1)

    CC_group.inputs["Bright"].min_value = -100
    CC_group.inputs["Bright"].max_value = 100

    CC_group.inputs["Contrast"].min_value = -100
    CC_group.inputs["Contrast"].max_value = 100

    CC_group.inputs["Hue"].default_value = 0.5
    CC_group.inputs["Hue"].min_value = 0
    CC_group.inputs["Hue"].max_value = 1

    CC_group.inputs["Saturation"].default_value = 1
    CC_group.inputs["Saturation"].min_value = 0
    CC_group.inputs["Saturation"].max_value = 1

    CC_group.inputs["Invert"].default_value = 0
    CC_group.inputs["Invert"].min_value = 0
    CC_group.inputs["Invert"].max_value = 1

    CC_group.inputs["Gamma"].default_value = 1
    CC_group.inputs["Gamma"].min_value = 0.01
    CC_group.inputs["Gamma"].max_value = 10

    group_outputs = CC_group.nodes.new("NodeGroupOutput")
    group_outputs.location = (1000, 0)
    CC_group.outputs.new("NodeSocketColor", "Color")

    BCNode = CC_group.nodes.new("ShaderNodeBrightContrast")
    BCNode.location = (200, 0)
    HSVNode = CC_group.nodes.new("ShaderNodeHueSaturation")
    HSVNode.location = (400, 0)
    InvertNode =  CC_group.nodes.new("ShaderNodeInvert")
    InvertNode.location = (600, 0)
    GammaNode = CC_group.nodes.new("ShaderNodeGamma")
    GammaNode.location = (800, 0)

    CC_group.links.new(group_inputs.outputs["Color"], BCNode.inputs["Color"])
    CC_group.links.new(group_inputs.outputs["Bright"], BCNode.inputs["Bright"])
    CC_group.links.new(group_inputs.outputs["Contrast"], BCNode.inputs["Contrast"])
    CC_group.links.new(group_inputs.outputs["Hue"], HSVNode.inputs["Hue"])
    CC_group.links.new(group_inputs.outputs["Saturation"], HSVNode.inputs["Saturation"])
    CC_group.links.new(group_inputs.outputs["Invert"], InvertNode.inputs["Fac"])
    CC_group.links.new(group_inputs.outputs["Gamma"], GammaNode.inputs["Gamma"])

    CC_group.links.new(BCNode.outputs["Color"], HSVNode.inputs["Color"])
    CC_group.links.new(HSVNode.outputs["Color"], InvertNode.inputs["Color"])
    CC_group.links.new(InvertNode.outputs["Color"], GammaNode.inputs["Color"])
    CC_group.links.new(GammaNode.outputs["Color"], group_outputs.inputs["Color"])

def ConvertMatrix(matrixstr):
    '''
    #### 转换max下的3x4Matrix
    '''
    # Max 输出为 3*4 矩阵
    # (matrix3 [0.766044,0.642788,0] [-0.642788,0.766044,0] [0,0,1] [2306.89,2755.7,0])

    # Blender 输出为 4*4 矩阵
    #<Matrix 4x4 ( 0.7660, -0.6428, 0.0000, 2306.8943)
    #            ( 0.6428,  0.7660, 0.0000, 2755.6978)
    #            (-0.0000, -0.0000, 1.0000,    0.0000)
    #            ( 0.0000,  0.0000, 0.0000,    1.0000)>

    a = matrixstr[9:-1].split()
    matrix = Matrix()
    for i in range(len(a)):
        b = eval(a[i])
        b.append(0) if i < 3 else b.append(1)
        matrix[i] = b

    return matrix.transposed()

def ConvertColor(color):
    _c = (color[7:-1]+" 255").split()
    _clr = [float(c)/255.0 for c in _c]
    return _clr

def CreateNode(nodes, links, xmlPath, ParentNode, texmap_type):
    '''
    #### nodes      :节点
    #### links      :连接
    #### xmlPath    :查找路径
    #### ParentNode :父级节点
    #### type       :节点类型
    '''
    texmap = xmlPath
    # print(texmap_type)
    _node = texmap.findall("./")
    
    # Bitmap 已完成
    if texmap_type == "Bitmap" :
        bitmap_path = _node[0].text        
        # Scale
        uTile = float(texmap.attrib["U_Tiling"])
        vTile = float(texmap.attrib["V_Tiling"])
        # Location
        uOffset = float(texmap.attrib["U_Offset"])
        vOffset = float(texmap.attrib["V_Offset"])
        #Rotation
        wAngle = float(texmap.attrib["W_Angle"])
        vAngle = float(texmap.attrib["V_Angle"])
        uAngle = float(texmap.attrib["U_Angle"])
        
        ImageShader = CreateImageNode(nodes, links, bitmap_path, -900, -150, position=(uOffset, vOffset, 0), rotation=(radians(uAngle), radians(vAngle), radians(wAngle)), scale=(uTile, vTile, 1))        
        links.new(ImageShader.outputs["Color"], ParentNode)
    
    # 平铺 已完成
    elif texmap_type == "Tiles" :
        BrickShader = nodes.new("ShaderNodeTexBrick")
        BrickShader.location = (-600, 0)
        links.new(BrickShader.outputs["Color"], ParentNode)

        # 平铺纹理基础参数设置
        Brick_Color = texmap.attrib["Brick_color"]
        Mortar_Color = texmap.attrib["Mortar_color"]
        BrickShader.inputs["Color1"].default_value = ConvertColor(Brick_Color)
        BrickShader.inputs["Color2"].default_value = ConvertColor(Brick_Color)
        BrickShader.inputs["Mortar"].default_value = ConvertColor(Mortar_Color)

        BrickShader.inputs["Scale"].default_value = 1
        BrickShader.inputs["Mortar Size"].default_value = float(texmap.attrib["Horizontal_Gap"]) / 100
        BrickShader.inputs["Brick Width"].default_value = 1 / float(texmap.attrib["Horizontal_Count"])
        BrickShader.inputs["Row Height"].default_value = 1 / float(texmap.attrib["Vertical_Count"])

        Brick_Type = texmap.attrib["Tile_Type"]
        Brick_offset = 0.5
        if Brick_Type == "5" :
            Brick_offset = 0
        elif Brick_Type == "0" :
            Brick_offset = texmap.attrib["Line_Shift"]
        
        BrickShader.offset = Brick_offset
        
        CreateUVMapping(nodes, links, BrickShader, -900, 300)

        # 判断分缝线有没有纹理，如果有创建相关节点
        if texmap.attrib["Mortar_Map"] != "undefined" :
            MortarNode = _node[0][0]
            MortarType = texmap.attrib["Mortar_Map"].split(":")[-1]
            CreateNode(nodes, links, MortarNode, BrickShader.inputs["Mortar"], MortarType)
        
        # 判断平铺有没有纹理，如果有创建相关节点
        if texmap.attrib["Bricks_Map"] != "undefined" :
            TileNode = _node[1][0]
            # print(TileNode)
            TileType = texmap.attrib["Bricks_Map"].split(":")[-1]
            CreateNode(nodes, links, TileNode, BrickShader.inputs["Color1"], TileType)
            CreateNode(nodes, links, TileNode, BrickShader.inputs["Color2"], TileType)

    # 混合 已完成
    elif texmap_type == "Mix" :
        MixShader = nodes.new("ShaderNodeMixRGB")
        # MixShader.location = (-600, 0)
        links.new(MixShader.outputs["Color"], ParentNode)

        # 基础参数设置
        amount = texmap.attrib["mixAmount"]
        color1 = texmap.attrib["color1"]
        color2 = texmap.attrib["color2"]
        MixShader.inputs["Fac"].default_value = float(amount)/100
        MixShader.inputs["Color1"].default_value = ConvertColor(color1)
        MixShader.inputs["Color2"].default_value = ConvertColor(color2)

        if texmap.attrib["map1"] != "undefined":
            map1Node = _node[0][0]
            map1Type = texmap.attrib["map1"].split(":")[-1]
            CreateNode(nodes, links, map1Node, MixShader.inputs["Color1"], map1Type)

        if texmap.attrib["map2"] != "undefined":
            map2Node = _node[1][0]
            map2Type = texmap.attrib["map2"].split(":")[-1]
            CreateNode(nodes, links, map2Node, MixShader.inputs["Color2"], map2Type)

        if texmap.attrib["Mask"] != "undefined":
            maskNode = _node[2][0]
            MaskType = texmap.attrib["Mask"].split(":")[-1]
            CreateNode(nodes, links, maskNode, MixShader.inputs["Fac"], MaskType)

    # 棋盘格  已完成
    elif texmap_type == "Checker":
        CheckerShader = nodes.new("ShaderNodeTexChecker")
        links.new(CheckerShader.outputs["Color"], ParentNode)

        #基础参数
        color1 = texmap.attrib["color1"]
        color2 = texmap.attrib["color2"]
        map1 = texmap.attrib["map1"]
        map2 = texmap.attrib["map2"]

        CheckerShader.inputs["Color1"].default_value = ConvertColor(color1)
        CheckerShader.inputs["Color2"].default_value = ConvertColor(color2)
        CheckerShader.inputs["Scale"].default_value = 2

        if map1 != "undefined" :
            map1Node = _node[0][0]
            map1Type = map1.split(":")[-1]
            CreateNode(nodes, links, map1Node, CheckerShader.inputs["Color1"], map1Type)

        if map2 != "undefined" :
            map2Node = _node[1][0]
            map2Type = map2.split(":")[-1]
            CreateNode(nodes, links, map2Node, CheckerShader.inputs["Color2"], map2Type)
        
        CreateUVMapping(nodes, links, CheckerShader, -900, 300)

    # 衰减  完成IOR部分，其它类型还没找到相应实现方式
    elif texmap_type == "Falloff":
        
        MixRGBShader = nodes.new("ShaderNodeMixRGB")
        links.new(MixRGBShader.outputs["Color"], ParentNode)

        # Map1
        if texmap.attrib["map1"] != "undefined":
            map1Node = _node[0][0]
            map1Type = texmap.attrib["map1"].split(":")[-1]
            CreateNode(nodes, links, map1Node, MixRGBShader.inputs["Color1"], map1Type)
        # Map2
        if texmap.attrib["map2"] != "undefined":
            map2Node = _node[1][0]
            map2Type = texmap.attrib["map2"].split(":")[-1]
            CreateNode(nodes, links, map2Node, MixRGBShader.inputs["Color2"], map2Type)

        # Falloff_Type = texmap.attrib["type"]
        # if Falloff_Type == "2":
        FresnelShader = nodes.new("ShaderNodeFresnel")
        links.new(FresnelShader.outputs["Fac"], MixRGBShader.inputs["Fac"])

        FresnelShader.inputs["IOR"].default_value = float(texmap.attrib["ior"])

    # 颜色校正节点 已完成
    elif texmap_type == "Color Correction":

        cc_group = nodes.new("ShaderNodeGroup")
        cc_group.node_tree = bpy.data.node_groups['ColorCorrection_RH']
        links.new(cc_group.outputs["Color"], ParentNode)

        cc_group.inputs["Color"].default_value = ConvertColor(texmap.attrib["color"])
        
        if texmap.attrib["rewireMode"] == "1":
            cc_group.inputs["Saturation"].default_value = 0
        elif texmap.attrib["rewireMode"] == "2":
            cc_group.inputs["Invert"].default_value = 1

        if texmap.attrib["LIGHTNESSMODE"] == "0":
            cc_group.inputs["Bright"].default_value = float(texmap.attrib["BRIGHTNESS"])/100.0
            cc_group.inputs["Contrast"].default_value = float(texmap.attrib["contrast"])/100.0
        else:
            cc_group.inputs["Gamma"].default_value = 1 / float(texmap.attrib["GAMMARGB"])

        cc_group.inputs["Hue"].default_value = float(texmap.attrib["HUESHIFT"])/360.0 + 0.5
        cc_group.inputs["Saturation"].default_value = float(texmap.attrib["saturation"])/100.0 + 1

        if texmap.attrib["map"] != "undefined" :
            mapNode = _node[0][0]
            mapType = texmap.attrib["map"].split(":")[-1]
            CreateNode(nodes, links, mapNode, cc_group.inputs["Color"], mapType)

    # 合成节点
    # RGB相乘节点，Alpha处理部分没完成
    elif texmap_type == "RGB Multiply" :
        MixShader = nodes.new("ShaderNodeMixRGB")
        links.new(MixShader.outputs["Color"], ParentNode)
        MixShader.blend_type = "MULTIPLY"
        MixShader.inputs["Fac"].default_value = 1
        MixShader.inputs["Color1"].default_value = ConvertColor(texmap.attrib["color1"])
        MixShader.inputs["Color2"].default_value = ConvertColor(texmap.attrib["color2"])

        if texmap.attrib["map1"] != "undefined" :
            map1Node = _node[0][0]
            map1Type = texmap.attrib["map1"].split(":")[-1]
            CreateNode(nodes, links, map1Node, MixShader.inputs["Color1"], map1Type)
        
        if texmap.attrib["map2"] != "undefined" :
            map2Node = _node[1][0]
            map2Type = texmap.attrib["map2"].split(":")[-1]
            CreateNode(nodes, links, map2Node, MixShader.inputs["Color2"], map2Type)
        
        # Alpha处理

    # 渐变节点,Blender不支持贴图，所以只保留颜色
    elif texmap_type == "Gradient" :
        GradientNode = nodes.new("ShaderNodeTexGradient")
        ColorRampNode = nodes.new("ShaderNodeValToRGB")

        links.new(GradientNode.outputs["Fac"], ColorRampNode.inputs["Fac"])
        links.new(ColorRampNode.outputs["Color"], ParentNode)
        
        if texmap.attrib["gradientType"] == "1":
            GradientNode.gradient_type = "SPHERICAL"
            CreateUVMapping(nodes, links, GradientNode, -900, 300, position=(-0.5, -0.5, -0.86))
        else:
            CreateUVMapping(nodes, links, GradientNode, -900, 300, position=(-0.5, -0.5, 0))

        ColorRampNode.color_ramp.elements.new(float(texmap.attrib["color2Pos"]))

        ColorRampNode.color_ramp.elements[0].color = ConvertColor(texmap.attrib["color1"])
        ColorRampNode.color_ramp.elements[1].color = ConvertColor(texmap.attrib["color2"])
        ColorRampNode.color_ramp.elements[2].color = ConvertColor(texmap.attrib["color3"])        

    # 渐变坡度节点
    elif texmap_type == "Gradient Ramp" :
        pass
        GradientNode = nodes.new("ShaderNodeTexGradient")
        ColorRampNode = nodes.new("ShaderNodeValToRGB")

        links.new(GradientNode.outputs["Fac"], ColorRampNode.inputs["Fac"])
        links.new(ColorRampNode.outputs["Color"], ParentNode)

    # 噪波节点
    # VrayCompTex

    elif texmap_type == "VRayDirt" :
        
        AONode = nodes.new("ShaderNodeAmbientOcclusion")
        MixShader = nodes.new("ShaderNodeMixRGB")

        links.new(AONode.outputs["AO"], MixShader.inputs["Fac"])
        links.new(MixShader.outputs["Color"], ParentNode)

        AONode.inputs["Color"].default_value = ConvertColor(texmap.attrib["occluded_color"])
        AONode.samples = int(texmap.attrib["subdivs"])
        AONode.inputs["Distance"].default_value = float(texmap.attrib["radius"])

        MixShader.inputs["Color1"].default_value = (0, 0, 0, 1)
        MixShader.inputs["Color2"].default_value = (1, 1, 1, 1)

        if texmap.attrib["consider_same_object_only"] == "false" :
            AONode.only_local = False
        else:
            AONode.only_local = True
        
        if texmap.attrib["mode"] == "4":
            AONode.inside = True
        else:
            AONode.inside = False

        if texmap.attrib["texmap_occluded_color"] != "undefined":
            OccludedMap = _node[0][0]
            OccludedType = texmap.attrib["texmap_occluded_color"].split(":")[-1]
            CreateNode(nodes, links, OccludedMap, MixShader.inputs["Color1"], OccludedType)
        if texmap.attrib["texmap_unoccluded_color"] != "undefined":
            UnoccludedMap = _node[1][0]
            UnoccludedType = texmap.attrib["texmap_unoccluded_color"].split(":")[-1]
            CreateNode(nodes, links, UnoccludedMap, MixShader.inputs["Color2"], UnoccludedType)
        if texmap.attrib["texmap_radius"] != "undefined" :
            RadiusMap = _node[2][0]
            RadiusType = texmap.attrib["texmap_radius"].split(":")[-1]
            CreateNode(nodes, links, RadiusMap, AONode.inputs[1], RadiusType)
            # CreateNode(nodes, links, RadiusMap, AONode.inputs["Radius"], RadiusType)

    elif texmap_type == "VRayColor2Bump":
        BumpNode = nodes.new("ShaderNodeBump")        
        links.new(BumpNode.outputs["Normal"], ParentNode)

        BumpNode.inputs["Strength"].default_value = 0.1

        if texmap.attrib["map"] != "undefined":
            map = texmap[1][0]
            map_type = texmap.attrib["map"].split(":")[-1]
            CreateNode(nodes, links, map, BumpNode.inputs["Height"], map_type)

    elif texmap_type == "VRayNormalMap":
        BumpNode = nodes.new("ShaderNodeBump")        
        links.new(BumpNode.outputs["Normal"], ParentNode)

        BumpNode.inputs["Strength"].default_value = 0.1

        if texmap.attrib["normal_map"] != "undefined" :
            normal_map = texmap[0][0]
            normal_map_type = texmap.attrib["normal_map"].split(":")[-1]
            CreateNode(nodes, links, normal_map, BumpNode.inputs["Normal"], normal_map_type)
        
        if texmap.attrib["bump_map"] != "undefined":
            height_map = texmap[1][0]
            height_map_type = texmap.attrib["bump_map"].split(":")[-1]
            CreateNode(nodes, links, height_map, BumpNode.inputs["Height"], height_map_type)

    elif texmap_type == "VRayBump2Normal":
        BumpNode = nodes.new("ShaderNodeBump")
        links.new(BumpNode.outputs["Normal"], ParentNode)

        if texmap.attrib["bump_map"] != "undefined" :
            bump_map = texmap[0][0]
            bump_map_type = texmap.attrib["bump_map"].split(":")[-1]
            CreateNode(nodes, links, bump_map, BumpNode.inputs["Height"], bump_map_type)

    elif texmap_type == "Vertex Color" :
        VCNode = nodes.new("ShaderNodeAttribute")
        VCNode.attribute_name = "Col"

        links.new(VCNode.outputs["Color"], ParentNode)
        pass
    
    elif texmap_type == "CoronaAO":

        pass
    # CoronaAO

def CreateUVMapping(nodes, links, ParentNode, node_x, node_y, Coords="UV", position=(0, 0, 0), rotation=(0, 0, 0), scale=(1, 1, 1)):
    '''
    #### Coords      :坐标,默认为 “UV”，参数列表:Generated, Normal, UV, Object, Camera, Window, Reflection
    #### position    :移动，默认为(0,0,0)
    #### rotation    :旋转角度
    #### scale       :缩放
    #### ParentNode  :父级节点
    #### node_x      :节点X方向位置
    #### node_y      :节点Y方向位置
    '''
    mapShader = nodes.new("ShaderNodeMapping")
    mapShader.location = (node_x, node_y)
    links.new(mapShader.outputs["Vector"], ParentNode.inputs["Vector"])

    mapShader.inputs["Location"].default_value = position
    mapShader.inputs["Rotation"].default_value = rotation
    mapShader.inputs["Scale"].default_value = scale

    texcoordShader = nodes.new("ShaderNodeTexCoord")
    texcoordShader.location = (node_x-200, node_y)
    links.new(texcoordShader.outputs[Coords], mapShader.inputs["Vector"])

def CreateImageNode(nodes, links, bitmap, node_x, node_y, Coors="UV", position=(0, 0, 0), rotation=(0, 0, 0), scale=(1, 1, 1)):
    '''
    #### bitmap      :图像路径
    #### Coords      :坐标,默认为 “UV”，参数列表:Generated, Normal, UV, Object, Camera, Window, Reflection
    #### position    :移动，默认为(0,0,0)
    #### rotation    :旋转角度
    #### scale       :缩放
    #### ParentNode  :父级节点
    #### node_x      :节点X方向位置
    #### node_y      :节点Y方向位置
    '''

    _, filename = os.path.split(bitmap)
    img = bpy_extras.image_utils.load_image(bitmap, check_existing=True)
    ImageShader = nodes.new("ShaderNodeTexImage")
    ImageShader.location = (node_x, node_y)
    
    if img != None:
        img.name = filename
        ImageShader.image = img

        CreateUVMapping(nodes, links, ImageShader, node_x - 300, node_y, Coors, position, rotation, scale)

    return ImageShader

def CreateSingleMtl(nodes, links, xmlPath):
    '''
    ### nodes : 节点组
    ### xmlPath: 查找节点位置
    '''
    bsdfShader = nodes.new("ShaderNodeBsdfPrincipled")
    bsdfShader.location = (-300, 0)
    
    NodeName = ("Diffuse", "Metallic", "Reflection", "Roughness", "Anisotropic", "AnisotropicRotation", "Sheen", "Coat", "CoatRoughness", "IOR", "Refraction", "RefractRoughness", "Emission", "EmissionStrength", "Opacity", "Bump", "Translucent", "Displacement")
    inputName = ("Base Color", "Metallic", "Specular", "Roughness", "Anisotropic", "Anisotropic Rotation", "Sheen", "Clearcoat","Clearcoat Roughness", "IOR", "Transmission", "Transmission Roughness", "Emission", "Emission Strength", "Alpha", "Normal", "Translucent", "Displacement")
    TextureClass = ("Bitmap", "Tiles", "Mix", "Falloff", "Color Correction", "RGB Multiply", "Gradient", "VRayDirt", "Gradient Ramp", "VRayColor2Bump", "VRayNormalMap", "VRayBump2Normal", "Vertex Color")

    useRoughness = xmlPath.attrib["useRoughness"]

    for path, input in zip(NodeName, inputName):
        node = xmlPath.find("./%s" % path)

        texmap = node.attrib["Texmap"]
        texmap_type = texmap.split(":")[-1]   

        texmap_node = xmlPath.find("./%s/" % path)

        if path in ("Diffuse", "Emission"):
            bsdfShader.inputs[input].default_value = ConvertColor(node.attrib["Color"])

            if texmap_type in TextureClass :
                CreateNode(nodes, links, texmap_node, bsdfShader.inputs[input], texmap_type)
        
        elif path in ("Metallic", "Reflection", "Roughness", "Anisotropic", "AnisotropicRotation", "Coat", "CoatRoughness", "IOR", "Refraction", "EmissionStrength", "Bump", "Displacement") :
            value = float(node.attrib["Amount"])
            if path == "Roughness" and useRoughness == "false":
                bsdfShader.inputs[input].default_value = 1 - value

                if texmap_type in TextureClass :
                    InvertNode = nodes.new("ShaderNodeInvert")
                    links.new(InvertNode.outputs["Color"], bsdfShader.inputs[input])
                    CreateNode(nodes, links, texmap_node, InvertNode.inputs["Color"], texmap_type)
            elif path == "Bump" :
                if texmap_type in TextureClass :
                    if texmap_type in ("Bitmap", "Tiles", "Mix", "Falloff", "Color Correction", "RGB Multiply", "Gradient", "VRayDirt", "Gradient Ramp") :
                        bumpShader = nodes.new("ShaderNodeBump")
                        bumpShader.inputs["Strength"].default_value = 0.1
                        links.new(bumpShader.outputs["Normal"], bsdfShader.inputs["Normal"])
                        CreateNode(nodes, links, texmap_node, bumpShader.inputs["Height"], texmap_type)
                    else :
                        # pass
                        CreateNode(nodes, links, texmap_node, bsdfShader.inputs["Normal"], texmap_type)
            elif path == "RefractRoughness" :
                bsdfShader.inputs[input].default_value = 1 - value                
            elif path in ("Translucent", "Displacement") :
                pass
            else:
                bsdfShader.inputs[input].default_value = value
                if texmap_type in TextureClass :
                    CreateNode(nodes, links, texmap_node, bsdfShader.inputs[input], texmap_type)

    return bsdfShader

class RedHalo_M2B_ImportSetting(bpy.types.PropertyGroup):
    # newfile :bpy.props.BoolProperty(name="New File", default=True, description = "New File")
    importSetting :bpy.props.BoolProperty(name="导入Max设置", default=True, description = "导入Max设置")
    importLight :bpy.props.BoolProperty(name="导入灯光", default=True, description = "导入灯光")
    importCamera :bpy.props.BoolProperty(name="导入相机", default=True)
    importProxy :bpy.props.BoolProperty(name="导入代理文件", default=True)
    importModel :bpy.props.BoolProperty(name="导入模型", default=True)
    importMaterial :bpy.props.BoolProperty(name="导入材质", default=True)

class Tools_OT_Max2Blender(Operator):
    bl_idname = "redhalo.maxtoblender"
    bl_label = "Import Max Scene"
    bl_description = "Import Max Scene"
    bl_options = {'REGISTER', 'UNDO'} 
    
    def execute(self, context): 
        import_path = tempfile.gettempdir()
        if getImportPath() != "":
            import_path = getImportPath()

        MTLFile = tempfile.gettempdir() + "\\RH_M2B.xml"
        xml_file = xml.parse(MTLFile)
        xml_root = xml_file.getroot()
        settings = context.scene.rh_m2b_settings

        # Gamma
        gamma = float(xml_root.find("./Setting/Gamma").text)
        
        # 文件单位
        units = xml_root.find("./Setting/Units").text
        fac = 1 #缩放系数
        if units == "millimeters":
            fac = 0.001
        if units == "meters":
            fac = 1
        if units == "inches":
            fac = 0.0254
        if units == "feet":
            fac = 0.3048
        if units == "miles":
            fac == 1609.3439893783
        if units == "centimeters":
            fac = 0.01
        if units == "kilometers":
            fac = 1000
        
        # 错误材质列表
        error_mat_list = []
        
        print("============RED HALO Studio============")
        print("==============发霉的红地蛋==============")

        # 加载模型
        if settings.importModel :
            print("========= 开始加载模型 Loading... =========")
            try:
                FBXFile = import_path + "\\RH_M2B.fbx"
                bpy.ops.import_scene.fbx(filepath=FBXFile, use_custom_normals=False, use_custom_props=False, use_anim=False)
                # bpy.ops.import_scene.fbx(filepath='', directory='', filter_glob='*.fbx', files=None, ui_tab='MAIN', 
                # use_manual_orientation=False, global_scale=1.0, bake_space_transform=False, 
                # use_custom_normals=True, use_image_search=True, 
                # use_alpha_decals=False, decal_offset=0.0, use_anim=True, 
                # anim_offset=1.0, use_subsurf=False, use_custom_props=True, 
                # use_custom_props_enum_as_string=True, ignore_leaf_bones=False, 
                # force_connect_children=False, automatic_bone_orientation=False, 
                # primary_bone_axis='Y', secondary_bone_axis='X', 
                # use_prepost_rot=True, axis_forward='-Z', axis_up='Y')
            except:
                return {'FINISHED'}
                pass
            
            print("========= 模型加载完成 Ended =========")
        
        # 设置自动平滑
        for i in bpy.data.meshes:
            i.use_auto_smooth = True

        # 设置场景
        if settings.importSetting :
            renderWidth = int(xml_root.find("./Setting/Width").text)
            renderHeight = int(xml_root.find("./Setting/Height").text)
            bpy.context.scene.render.resolution_x = renderWidth
            bpy.context.scene.render.resolution_y = renderHeight

        # 设置相机
        if settings.importCamera :
            camera_xml = xml_root.find("./CameraList")
            for c in camera_xml.findall("./*") :
                camera_name = c.attrib["name"]
                camera_matrix = ConvertMatrix(c.attrib["matrix"])
                camera_fov = c.attrib["fov"]
                camera_near = c.attrib["near"]
                camera_far = c.attrib["far"]

                camera_data = bpy.data.cameras.new(name='Camera')
                camera_object = bpy.data.objects.new(camera_name, camera_data)
                bpy.context.scene.collection.objects.link(camera_object)
                camera_object.data.angle = float(camera_fov)/180 * pi
                camera_object.data.clip_start = float(camera_near) * fac
                camera_object.data.clip_end = float(camera_far) * fac           

                camera_object.matrix_world = camera_matrix * fac
                camera_object.scale = (1, 1, 1)

        # 设置灯光
        if settings.importLight :
            print("========= 加载灯光设置 Loading... =========")

            light_xml = xml_root.find("./LightList")
            # c = light_xml.getchildren()
            for x in light_xml.findall("./*"):
                light_name = x.attrib["name"]
                matrix = ConvertMatrix(x.attrib["matrix"])

                L_Type = x.attrib["type"]

                if L_Type in ("AREA", "DISK"):
                    light_data = bpy.data.lights.new(name="Light", type = "AREA")
                else:
                    light_data = bpy.data.lights.new(name="Light", type = L_Type)

                light_obj = bpy.data.objects.new(light_name, light_data)
                light_obj.data.energy = float(x.attrib["multiplier"])
                color = ConvertColor(x.attrib["color"])
                light_obj.data.color = color[:-1]
                if L_Type == "POINT":
                    light_obj.data.shadow_soft_size = float(x.attrib["length"]) 
                elif L_Type == "AREA":
                    light_obj.data.shape = 'RECTANGLE'
                    light_obj.data.size = float(x.attrib["length"]) * fac
                    light_obj.data.size_y = float(x.attrib["width"]) * fac
                    light_obj.data.cycles.is_portal = True if x.attrib["portal"] == "true" else False
                elif L_Type == "DISK":
                    light_obj.data.shape = 'DISK'
                    light_obj.data.size = float(x.attrib["length"]) * fac
                    light_obj.data.size_y = float(x.attrib["width"]) * fac
                    light_obj.data.cycles.is_portal = True if x.attrib["portal"] == "true" else False
                elif L_Type == "SUN":
                    light_obj.data.angle = 0.01
                elif L_Type == "SPOT" :
                    pass

                bpy.context.scene.collection.objects.link(light_obj)

                light_obj.matrix_world = matrix * fac
                light_obj.scale *= 1 / fac

                light_obj.visible_camera = True if x.attrib["invisible"] == "true" else False
                light_obj.visible_diffuse = True if x.attrib["affectdiffuse"] == "true" else False
                light_obj.visible_glossy = True if x.attrib["affectspecular"] == "true" else False
                light_obj.visible_transmission = True if x.attrib["affectreflections"] == "true" else False

            print("========= 灯光设置完成 Ended =========")

        # 设置材质
        if settings.importMaterial :
            print("========= 加载材质 Loading... =========")
            SceneMaterials = [ m for m in bpy.data.materials[:] if not m.is_grease_pencil]
            
            Create_ColorCorrection()

            m_mat = xml_root.find("./MaterialList/")

            for mat in SceneMaterials:
                material_name = mat.name
                nodes = mat.node_tree.nodes
                links = mat.node_tree.links
                
                m = xml_root.find("./MaterialList/*/[@name='%s']" % material_name)

                # print(material_name)
                if m :
                    try:
                        nodes.clear()
                        outputShader = nodes.new("ShaderNodeOutputMaterial")

                        if m.tag == "DoubleSideMtl" :
                            DoubleMixShader = nodes.new("ShaderNodeMixShader")
                            links.new(DoubleMixShader.outputs["Shader"], outputShader.inputs["Surface"])
                            DoubleMixShader.location = (0, -150)
                            
                            frontMtl = m.attrib["frontMtl"].split(":")[0]
                            backMtl = m.attrib["backMtl"].split(":")[0]

                            if frontMtl != "undefined" :
                                FMat = xml_root.find("./MaterialList/SingleMtl/[@name='%s']" % frontMtl)
                                node = CreateSingleMtl(nodes, links, FMat)
                                links.new(node.outputs["BSDF"], DoubleMixShader.inputs[1])
                            if backMtl != "undefined" :
                                back = xml_root.find("./MaterialList/SingleMtl/[@name='%s']" % backMtl)
                                node = CreateSingleMtl(nodes, links, back)
                                links.new(node.outputs["BSDF"], DoubleMixShader.inputs[2])
                            
                            translucency_color = ConvertColor(m.attrib["translucency"])
                            translucency_map = m.attrib["texmap_translucency"]
                            translucency_amount = m.attrib["texmap_translucency_multiplier"]

                            amount = colorsys.rgb_to_hsv(translucency_color[0], translucency_color[1], translucency_color[2])[2] * float(translucency_amount) / 100.0

                            DoubleMixShader.inputs["Fac"].default_value = amount * float(translucency_amount) / 100
                                
                        elif m.tag == "SingleMtl" :
                            node = CreateSingleMtl(nodes, links, m)
                            links.new(node.outputs["BSDF"], outputShader.inputs["Surface"])
                            
                            # TranslucecyNode
                            translucency_path = m.find("./Translucent")
                            if translucency_path.attrib["Texmap"] != "undefined" :
                                AddShader = nodes.new("ShaderNodeAddShader")
                                TranslucentShader = nodes.new("ShaderNodeBsdfTranslucent")

                                links.new(TranslucentShader.outputs["BSDF"], AddShader.inputs[1])
                                links.new(node.outputs["BSDF"], AddShader.inputs[0])
                                links.new(AddShader.outputs["Shader"], outputShader.inputs["Surface"])
                                
                                texmap_type = translucency_path.attrib["Texmap"].split(":")[-1]

                                CreateNode(nodes, links, translucency_path[0], TranslucentShader.inputs["Color"], texmap_type)
                            else:
                                links.new(node.outputs["BSDF"], outputShader.inputs["Surface"])

                            # Displacement
                            Displacement_path = m.find("./Displacement")
                            if Displacement_path.attrib["Texmap"] != "undefined" :
                                DisplacementShader = nodes.new("ShaderNodeDisplacement")
                                texmap_type = Displacement_path.attrib["Texmap"].split(":")[-1]

                                CreateNode(nodes, links, Displacement_path[0], DisplacementShader.inputs["Normal"], texmap_type)
                            
                        elif m.tag == "LightMtl" :
                            emissionShader = nodes.new("ShaderNodeEmission")
                            
                            doubleSideShader = nodes.new("ShaderNodeMixShader")
                            mixTransShader = nodes.new("ShaderNodeMixShader")
                            TransparentShader = nodes.new("ShaderNodeBsdfTransparent")
                            GeometryShader = nodes.new("ShaderNodeNewGeometry")
                            MathShader = nodes.new("ShaderNodeMath")

                            links.new(GeometryShader.outputs["Backfacing"], MathShader.inputs[0])
                            links.new(MathShader.outputs["Value"], doubleSideShader.inputs["Fac"])
                            links.new(emissionShader.outputs["Emission"], doubleSideShader.inputs[1])
                            links.new(doubleSideShader.outputs["Shader"], mixTransShader.inputs[1])
                            links.new(TransparentShader.outputs["BSDF"], doubleSideShader.inputs[2])
                            links.new(TransparentShader.outputs["BSDF"], mixTransShader.inputs[2])
                            links.new(mixTransShader.outputs["Shader"], outputShader.inputs["Surface"])

                            emissionShader.location = (-750, 0)
                            mixTransShader.location = (-250, 0)
                            doubleSideShader.location = (-500, 0)
                            MathShader.location = (-750, 200)
                            GeometryShader.location = (-1000, 300)
                            TransparentShader.location = (-750, -200)

                            # 设置参数
                            emissionShader.inputs["Color"].default_value = ConvertColor(m.attrib["color"])
                            emissionShader.inputs["Strength"].default_value = float(m.attrib["multiplier"])

                            mixTransShader.inputs["Fac"].default_value = 0
                            MathShader.operation = 'MULTIPLY'
                            if m.attrib["twoSided"] == "false":
                                MathShader.inputs[1].default_value = 1
                            else :
                                MathShader.inputs[1].default_value = 0

                            if m.attrib["texmap"] != "undefined":                            
                                texmap_type = m.attrib["texmap"].split(":")[-1]
                                CreateNode(nodes, links, m[0][0], emissionShader.inputs["Color"], texmap_type)
                            
                            if m.attrib["opacity_texmap"] != "undefined" :
                                texmap_type = m.attrib["texmap"].split(":")[-1]
                                CreateNode(nodes, links, m[1][0], mixTransShader.inputs["Fac"], texmap_type)

                        elif m.tag == "OverrideMtl" :

                            pass
                    except:
                        error_mat_list.append(material_name)

        # 错误材质列表
        if len(error_mat_list) > 0:
            
            self.report({'ERROR'}, (str(len(error_mat_list)) + "个材质无法导入,详细列表看控制台"))
            
            print("\t {} 材质不能导入".format(len(error_mat_list)))
            
            for i,m in enumerate(error_mat_list):
                print("\t{}/{}:{}".format(i+1, len(error_mat_list),m))
        
        print("========= 材质加载完成 Ended =========")
        print("=========== RED HALO Studio =========")

        return {'FINISHED'}

class VIEW3D_PT_RedHaloM3B(bpy.types.Panel):
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'RedHalo'    
    bl_label = "REDHALO Max to Blender"

    def draw(self, context):
        settings = context.scene.rh_m2b_settings
        layout = self.layout
        version = "2022-02-22"

        # layout.prop(settings, "newfile")
        layout.label(text="当前版本：" + version , icon='QUESTION')
        layout.label(text="使用此插件前", icon='ERROR')
        layout.label(text="建议新的空场景", icon='ERROR')
        layout.prop(settings, "importSetting", icon='PREFERENCES')
        layout.prop(settings, "importCamera", icon='CAMERA_DATA')
        layout.prop(settings, "importLight", icon='LIGHT_DATA')
        layout.prop(settings, "importModel", icon='MESH_DATA')
        layout.prop(settings, "importProxy", icon='LINK_BLEND')
        layout.prop(settings, "importMaterial", icon='MATERIAL')

        row = layout.column(align=True)
        row.scale_y = 1.5
        row.operator('redhalo.maxtoblender', icon='IMPORT',text = "Max to Blender")

classes = (
    RedHalo_M2B_ImportSetting,
    Tools_OT_Max2Blender,
    VIEW3D_PT_RedHaloM3B
)

def register():
    for cls in classes:
        bpy.utils.register_class(cls)
    bpy.types.Scene.rh_m2b_settings = bpy.props.PointerProperty(
        type=RedHalo_M2B_ImportSetting
    )

def unregister():
    for cls in reversed(classes):
        bpy.utils.unregister_class(cls)
    del bpy.types.Scene.rh_m2b_settings