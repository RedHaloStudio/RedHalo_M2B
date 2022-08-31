bl_info = {  
    "name": "REDHALO_IMPORT_MAX_SCENE",  
    "author": "Red Halo Studio",  
    "version": (0, 6),  
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
from mathutils import Matrix, Vector
from xml.etree import ElementTree as xml
from winreg import *
import traceback

def FixDaeName(string):
    # fbxname = "FBXASC231FBXASC170FBXASC151FBXASC229FBXASC184FBXASC152"
    names = [chr(int(i)) for i in string.split("FBXASC")[1:]]
    str = "".join(names)
    return str.encode("iso-8859-1").decode("utf-8")

def GetImportPath():
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
    _node = texmap.findall("./")
    
    # Bitmap 已完成
    if texmap_type in ("Bitmap", "VRayBitmap") :
        bitmap_path = _node[0].text
        if bitmap_path != "":            
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
            # Mapping
            mapping = int(texmap.attrib["Mapping"])
            mappingtype = int(texmap.attrib["MappingType"])
            
            ImageShader = CreateImageNode(nodes, links, bitmap_path, position=(uOffset, vOffset, 0), rotation=(radians(uAngle), radians(vAngle), radians(wAngle)), scale=(uTile, vTile, 1), mapping=mapping, mappingtype=mappingtype)     
            links.new(ImageShader.outputs["Color"], ParentNode)
    
    # 平铺 已完成
    elif texmap_type == "Tiles" :
        BrickShader = nodes.new("ShaderNodeTexBrick")
        # BrickShader.location = p_loc - Vector((p_width + 100, 0))
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
        
        CreateUVMapping(nodes, links, BrickShader)

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
    elif texmap_type in ("Mix", "RGB_Multiply", "CoronaMix", "RGB_Multiply", "VRayCompTex") :
        #  #### Params : Color1 Color2 MixAmount Texmap1 Texmap2 TexmapMask MixMode
        #  MixMode:
        #  ADD SUBTRACT MULTIPLY DIVIDE MINIMUM MAXIMUM MIX GAMMA DIFFERENCE SCREEN OVERLAY COLORDODGE COLORBURN LINEARBURN LINEARLIGHT SOFTLIGHT HARDLIGHT VIVIDLIGHT PINLIGHT HARDMIX EXCLUSION

        MixShader = nodes.new("ShaderNodeMixRGB")
        # MixShader.location = p_loc - Vector((p_width + 100, 0))
        links.new(MixShader.outputs["Color"], ParentNode)

        # 基础参数设置
        amount = texmap.attrib["MixAmount"]
        color1 = texmap.attrib["Color1"]
        color2 = texmap.attrib["Color2"]
        MixShader.inputs["Fac"].default_value = float(amount)/100
        MixShader.inputs["Color1"].default_value = ConvertColor(color1)
        MixShader.inputs["Color2"].default_value = ConvertColor(color2)
        MixShader.blend_type = texmap.attrib["MixMode"]

        if texmap.attrib["Texmap1"] != "undefined":
            map1Node = _node[0][0]
            map1Type = texmap.attrib["Texmap1"].split(":")[-1]
            CreateNode(nodes, links, map1Node, MixShader.inputs["Color1"], map1Type)

        if texmap.attrib["Texmap2"] != "undefined":
            map2Node = _node[1][0]
            map2Type = texmap.attrib["Texmap2"].split(":")[-1]
            CreateNode(nodes, links, map2Node, MixShader.inputs["Color2"], map2Type)

        if texmap.attrib["TexmapMask"] != "undefined":
            maskNode = _node[2][0]
            MaskType = texmap.attrib["TexmapMask"].split(":")[-1]
            CreateNode(nodes, links, maskNode, MixShader.inputs["Fac"], MaskType)

    # 棋盘格  已完成
    elif texmap_type == "Checker":
        CheckerShader = nodes.new("ShaderNodeTexChecker")
        # CheckerShader.location = p_loc - Vector((p_width + 100, 0))
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
        
        CreateUVMapping(nodes, links, CheckerShader)

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
    elif texmap_type in ("Color Correction","CoronaColorCorrect"):
        # ### Params:
        # #### Color Map Hue Saturation Brightness Contrast Gamma ColorMode
        ###### ColorMode --> NORAML INVERT MONO
        cc_group = nodes.new("ShaderNodeGroup")
        # cc_group.location = p_loc - Vector((p_width + 100, 0))
        cc_group.node_tree = bpy.data.node_groups['ColorCorrection_RH']
        links.new(cc_group.outputs["Color"], ParentNode)

        cc_group.inputs["Color"].default_value = ConvertColor(texmap.attrib["Color"])
        
        if texmap.attrib["ColorMode"] == "MONO":
            cc_group.inputs["Saturation"].default_value = 0
        elif texmap.attrib["ColorMode"] == "INVERT":
            cc_group.inputs["Invert"].default_value = 1

        cc_group.inputs["Bright"].default_value = float(texmap.attrib["Brightness"])/100.0
        cc_group.inputs["Contrast"].default_value = float(texmap.attrib["Contrast"])/100.0
        cc_group.inputs["Gamma"].default_value = 1 / float(texmap.attrib["Gamma"])

        cc_group.inputs["Hue"].default_value = float(texmap.attrib["Hue"])/360.0 + 0.5
        cc_group.inputs["Saturation"].default_value = float(texmap.attrib["Saturation"])/100.0 + 1

        if texmap.attrib["Map"] != "undefined" :
            mapNode = _node[0][0]
            mapType = texmap.attrib["Map"].split(":")[-1]
            CreateNode(nodes, links, mapNode, cc_group.inputs["Color"], mapType)

    # 渐变节点,Blender不支持贴图，所以只保留颜色
    elif texmap_type == "Gradient" :
        GradientNode = nodes.new("ShaderNodeTexGradient")
        ColorRampNode = nodes.new("ShaderNodeValToRGB")

        links.new(GradientNode.outputs["Fac"], ColorRampNode.inputs["Fac"])
        links.new(ColorRampNode.outputs["Color"], ParentNode)
        
        if texmap.attrib["gradientType"] == "1":
            GradientNode.gradient_type = "SPHERICAL"
            CreateUVMapping(nodes, links, GradientNode, position=(-0.5, -0.5, -0.86))
        else:
            CreateUVMapping(nodes, links, GradientNode, position=(-0.5, -0.5, 0))

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

    # AO
    elif texmap_type in ("VRayDirt", "CoronaAO") : 
        # Params Radius OccludedColor UnoccludedColor Subdivs OnlySameObject TexmapRadius TexmapOccluded TexmapUnoccluded Mode
        # Mode : OUTSIDE INSIDE BOTH
        MixShader = nodes.new("ShaderNodeMixRGB")

        AONode = nodes.new("ShaderNodeAmbientOcclusion")
        AONode.location = MixShader.location - Vector((MixShader.width + 100, -100))

        links.new(AONode.outputs["AO"], MixShader.inputs["Fac"])
        links.new(MixShader.outputs["Color"], ParentNode)

        AONode.inputs["Color"].default_value = ConvertColor(texmap.attrib["OccludedColor"])
        AONode.samples = int(texmap.attrib["Subdivs"])
        AONode.inputs["Distance"].default_value = float(texmap.attrib["Radius"])

        MixShader.inputs["Color1"].default_value = (0, 0, 0, 1)
        MixShader.inputs["Color2"].default_value = (1, 1, 1, 1)

        if texmap.attrib["OnlySameObject"] == "false" :
            AONode.only_local = False
        else:
            AONode.only_local = True
        
        if texmap.attrib["Mode"] == "INSIDE":
            AONode.inside = True
        else:
            AONode.inside = False

        if texmap.attrib["TexmapOccluded"] != "undefined":
            OccludedMap = _node[0][0]
            OccludedType = texmap.attrib["TexmapOccluded"].split(":")[-1]
            CreateNode(nodes, links, OccludedMap, MixShader.inputs["Color1"], OccludedType)
        
        if texmap.attrib["TexmapUnoccluded"] != "undefined":
            UnoccludedMap = _node[1][0]
            UnoccludedType = texmap.attrib["TexmapUnoccluded"].split(":")[-1]
            CreateNode(nodes, links, UnoccludedMap, MixShader.inputs["Color2"], UnoccludedType)

        if texmap.attrib["TexmapRadius"] != "undefined" :
            RadiusMap = _node[2][0]
            RadiusType = texmap.attrib["TexmapRadius"].split(":")[-1]
            CreateNode(nodes, links, RadiusMap, AONode.inputs[1], RadiusType)

    # 法线/凹凸
    elif texmap_type in ("VRayColor2Bump", "VRayNormalMap", "CoronaNormal", "VRayBump2Normal", "CoronaBumpConverter") :
        '''
        #### Params : NormalMap BumpMap BumpStrength NormalStrength FlipRed FilpGreen SweepRedGreen
        '''
        BumpNode = None
        NormalNode = None

        if texmap.attrib["NormalMap"] != "undefined" :
            NormalNode = nodes.new("ShaderNodeNormalMap")
            NormalNode.inputs["Strength"].default_value = 1.0 # float(texmap.attrib["NormalStrength"])

            normal_map = texmap[0][0]
            normal_map_type = texmap.attrib["NormalMap"].split(":")[-1]
            CreateNode(nodes, links, normal_map, NormalNode.inputs["Color"], normal_map_type)

        if texmap.attrib["BumpMap"] != "undefined" :
            BumpNode = nodes.new("ShaderNodeBump")
            BumpNode.inputs["Strength"].default_value = 0.2 #float(texmap.attrib["BumpStrength"])

            Bump_Map = texmap[1][0]
            Bump_Map_Type = texmap.attrib["BumpMap"].split(":")[-1]
            CreateNode(nodes, links, Bump_Map, BumpNode.inputs["Height"], Bump_Map_Type)
        
        if BumpNode is None :
            links.new(NormalNode.outputs["Normal"], ParentNode)
        elif NormalNode is None:
            links.new(BumpNode.outputs["Normal"], ParentNode)
        else:
            links.new(NormalNode.outputs["Normal"], BumpNode.inputs["Normal"])
            links.new(BumpNode.outputs["Normal"], ParentNode)

    elif texmap_type == "Vertex Color" :
        VCNode = nodes.new("ShaderNodeAttribute")
        VCNode.attribute_name = "Col"

        links.new(VCNode.outputs["Color"], ParentNode)
        pass
    
def CreateUVMapping(nodes, links, ParentNode, Coords="UV", position=(0, 0, 0), rotation=(0, 0, 0), scale=(1, 1, 1)):
    '''
    #### Coords      :坐标,默认为 “UV”，参数列表:Generated, Normal, UV, Object, Camera, Window, Reflection
    #### position    :移动，默认为(0,0,0)
    #### rotation    :旋转角度
    #### scale       :缩放
    #### ParentNode  :父级节点
    '''
    mapShader = nodes.new("ShaderNodeMapping")
    links.new(mapShader.outputs["Vector"], ParentNode.inputs["Vector"])
    
    mapShader.location = ParentNode.location - Vector((ParentNode.width, 0))

    mapShader.inputs["Location"].default_value = position
    mapShader.inputs["Rotation"].default_value = rotation
    mapShader.inputs["Scale"].default_value = scale

    texcoordShader = nodes.new("ShaderNodeTexCoord")

    links.new(texcoordShader.outputs[Coords], mapShader.inputs["Vector"])

def CreateImageNode(nodes, links, bitmap, Coors="UV", position=(0, 0, 0), rotation=(0, 0, 0), scale=(1, 1, 1), mapping=0, mappingtype=0):
    '''
    #### bitmap      :图像路径
    #### Coords      :坐标,默认为 “UV”，参数列表:Generated, Normal, UV, Object, Camera, Window, Reflection
    #### position    :移动，默认为(0,0,0)
    #### rotation    :旋转角度
    #### scale       :缩放
    #### ParentNode  :父级节点
    '''

    _, filename = os.path.split(bitmap)
    img = bpy_extras.image_utils.load_image(bitmap, check_existing=True)    
    
    if img:        
        if mappingtype == 1:
            # Sphere Environ
            if mapping == 0:
                ImageShader = nodes.new("ShaderNodeTexEnvironment")
        else:
            ImageShader = nodes.new("ShaderNodeTexImage")
    
        img.name = filename
        ImageShader.image = img

        if mappingtype == 1:
            # Sphere Environ
            if mapping == 0:
                CreateUVMapping(nodes, links, ImageShader, "Generated", position, rotation, scale)
            if mapping == 3:
                CreateUVMapping(nodes, links, ImageShader, "Window", position, rotation, scale)
        else:
            CreateUVMapping(nodes, links, ImageShader, "UV", position, rotation, scale)

    return ImageShader

def CreateSingleMtl(nodes, links, xmlPath):
    '''
    ### nodes : 节点组
    ### xmlPath: 查找节点位置
    '''
    bsdfShader = nodes.new("ShaderNodeBsdfPrincipled")
    bsdfShader.location = (-300, 0)
    
    # NodeName = ("Diffuse", "Metallic", "Reflection", "Roughness", "Anisotropic", "AnisotropicRotation", "Sheen", "Coat", "CoatRoughness", "IOR", "Refraction", 
    # "RefractRoughness", "Emission", "EmissionStrength", "Opacity", "Bump", "Translucent", "Displacement")
    # inputName = ("Base Color", "Metallic", "Specular", "Roughness", "Anisotropic", "Anisotropic Rotation", "Sheen", "Clearcoat","Clearcoat Roughness", "IOR", "Transmission", 
    # "Transmission Roughness", "Emission", "Emission Strength", "Alpha", "Normal", "Translucent", "Displacement")
    
    NodeName = ("Diffuse", "Metallic", "Reflection", "Roughness", "Anisotropic", "AnisotropicRotation", "Sheen", "Coat", "CoatRoughness", "IOR", "Refraction", "RefractRoughness", "Emission", "EmissionStrength", "Opacity", "Bump")
    inputName = ("Base Color", "Metallic", "Specular", "Roughness", "Anisotropic", "Anisotropic Rotation", "Sheen", "Clearcoat", "Clearcoat Roughness", "IOR", "Transmission", "Transmission Roughness", "Emission", "Emission Strength", "Alpha", "Normal")

    useRoughness = xmlPath.attrib["useRoughness"]

    #Diffuse #Metallic #Reflection #Anisotropic #AnisotropicRotation #Sheen #Coat #IOR #Refraction #RefractRoughness #Emission #EmissionStrength #Bump
    for path, input in zip(NodeName, inputName):
        node = xmlPath.find("./%s" % path)

        Default_Value = 1.0
        if "Color" in node.attrib :
            Default_Value = ConvertColor(node.attrib["Color"])
        
        if "Amount" in node.attrib :
            Default_Value = float(node.attrib["Amount"])
        
        texmap = node.attrib["Texmap"]
        texmap_type = texmap.split(":")[-1]
        texmap_node = xmlPath.find("./%s/" % path)

        parent_node = bsdfShader.inputs[input]        
        if path in ("Roughness", "CoatRoughness", "RefractRoughness") :
            if useRoughness == "false" or path == "RefractRoughness":
                parent_node.default_value = 1 - Default_Value
                if texmap_node:
                    InvertNode = nodes.new("ShaderNodeInvert")
                    links.new(InvertNode.outputs["Color"], parent_node)
                    CreateNode(nodes, links, texmap_node, InvertNode.inputs["Color"], texmap_type)
        elif path in ("Bump"):
            if texmap_node:
                BumpNode = nodes.new("ShaderNodeBump")
                BumpNode.inputs["Strength"].default_value = 0.2
                links.new(BumpNode.outputs["Normal"], parent_node)
                CreateNode(nodes, links, texmap_node, BumpNode.inputs["Height"], texmap_type)
        else:
            parent_node.default_value = Default_Value
            if texmap_node:
                CreateNode(nodes, links, texmap_node, parent_node, texmap_type)
    
    return bsdfShader

class RedHalo_M2B_ImportSetting(bpy.types.PropertyGroup):
    importSetting :bpy.props.BoolProperty(name="导入Max设置", default=True, description = "导入Max设置")
    importLight :bpy.props.BoolProperty(name="导入灯光", default=True, description = "导入灯光")
    importEnvironment :bpy.props.BoolProperty(name="导入环境", default=True, description = "导入环境")
    importCamera :bpy.props.BoolProperty(name="导入相机", default=True)
    importAnimate :bpy.props.BoolProperty(name="导入动画", default=True)
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
        if GetImportPath() != "":
            import_path = GetImportPath()

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
                use_anim = True if settings.importAnimate else False
                bpy.ops.import_scene.fbx(filepath=FBXFile, use_custom_normals=False, use_custom_props=False, use_anim=use_anim, automatic_bone_orientation=True)
                # bpy.ops.import_scene.fbx(filepath='', directory='', filter_glob='*.fbx', files=None, ui_tab='MAIN', 
                # use_manual_orientation=False, global_scale=1.0, bake_space_transform=False, 
                # use_custom_normals=True, use_image_search=True, 
                # use_alpha_decals=False, decal_offset=0.0, use_anim=True, 
                # anim_offset=1.0, use_subsurf=False, use_custom_props=True, 
                # use_custom_props_enum_as_string=True, ignore_leaf_bones=False, 
                # force_connect_children=False, automatic_bone_orientation=False, 
                # primary_bone_axis='Y', secondary_bone_axis='X', 
                # use_prepost_rot=True, axis_forward='-Z', axis_up='Y')

                objects_list = xml_root.find("./ObjectList")

                for obj in objects_list.findall("./*") :                    
                    object_name = obj.attrib["name"]
                    
                    # bpy.context.object.hide_render = True
                    object_Render = True if obj.attrib["Render"] == "true" else False
                    
                    # bpy.context.object.visible_camera = False
                    object_camera = True if obj.attrib["Camera"] == "true" else False
                    # bpy.context.object.visible_diffuse = False
                    
                    # bpy.context.object.visible_transmission = False
                    # bpy.context.object.visible_glossy = False
                    object_reflect = True if obj.attrib["Reflect"] == "true" else False
                    
                    # bpy.context.object.visible_shadow = False
                    object_shadow = True if obj.attrib["Shadow"] == "true" else False
                    
                    # bpy.context.object.visible_volume_scatter = False
                    object_atmospherics = True if obj.attrib["Atmospherics"] == "true" else False
                    obj_scene = bpy.data.objects[object_name]
                    
                    obj_scene.hide_render = object_Render
                    # befor 3.00
                    if bpy.app.version < (3, 0, 0):
                        obj_vis = obj_scene.cycles_visibility
                        obj_vis.camera = object_camera
                        # obj_vis.diffuse = False
                        obj_vis.glossy = object_reflect
                        obj_vis.transmission = object_reflect
                        obj_vis.scatter = object_atmospherics
                        obj_vis.shadow = object_shadow

                    # 3.00 later
                    else:
                        obj_scene.visible_camera = object_camera
                        # obj_scene.visible_diffuse = False
                        obj_scene.visible_glossy = object_reflect
                        obj_scene.visible_transmission = object_reflect
                        obj_scene.visible_volume_scatter = object_atmospherics
                        obj_scene.visible_shadow = object_shadow

            except:
                return {'FINISHED'}
            
            print("========= 模型加载完成 Ended =========")
        
        # 把所有物体移动到新的集合中
        import_name = xml_root.find("./Setting/File").text
        Arch_Col = bpy.data.collections.new(import_name)
        bpy.context.collection.children.link(Arch_Col)

        objects_col = bpy.data.collections.new("Objects")
        Arch_Col.children.link(objects_col)

        for i in bpy.data.objects:
            objects_col.objects.link(i)
            bpy.context.collection.objects.unlink(i)

        # 设置代理模型
        if settings.importProxy :
            proxy_list = xml_root.find("./Proxy")

            proxy_col = bpy.data.collections.new("Proxy")
            Arch_Col.children.link(proxy_col)

            for p in proxy_list:
                proxy_source = p.attrib["name"]

                source_obj_name = proxy_source[10:]
                # RHPROXYSOURCE_3E65CFD9252849E484B3DBAFBA1F63CF_objarchmodels58_005_00
                _src_obj = bpy.data.objects[proxy_source]
                me = bpy.data.objects[proxy_source].data
                
                empty_parent = bpy.data.objects.new((source_obj_name +"_Parent"), None)
                _tmp_empty_obj = bpy.data.objects.new("TMPPROXY_Empty", None)
                proxy_col.objects.link(empty_parent)

                proxy_ins_item = p

                for idx, item in enumerate(proxy_ins_item):
                    item_name = item.attrib["name"]
                    item_matrix = ConvertMatrix(item.attrib["matrix"])

                    _tmp_obj = bpy.data.objects.new(item_name, me)
                    _tmp_obj.display_type = "BOUNDS"
                    _tmp_obj.matrix_world = item_matrix * fac

                    # bpy.context.collection.objects.link(_tmp_obj)
                    proxy_col.objects.link(_tmp_obj)
                    _tmp_obj.parent = empty_parent

                #Delete Origin objects
                bpy.data.objects.remove(_src_obj)

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

            camera_col = bpy.data.collections.new("Camera")
            Arch_Col.children.link(camera_col)

            for c in camera_xml.findall("./*") :
                camera_name = c.attrib["name"]
                camera_matrix = ConvertMatrix(c.attrib["matrix"])
                camera_fov = c.attrib["fov"]
                camera_clip = c.attrib["clip"]
                camera_near = c.attrib["near"]
                camera_far = c.attrib["far"]

                camera_data = bpy.data.cameras.new(name='Cameras')
                camera_object = bpy.data.objects.new(camera_name, camera_data)
                camera_col.objects.link(camera_object)
                camera_object.data.angle = float(camera_fov)/180 * pi
                if camera_clip == "true":
                    camera_object.data.clip_start = float(camera_near) * fac
                    camera_object.data.clip_end = float(camera_far) * fac           

                camera_object.matrix_world = camera_matrix * fac
                camera_object.scale = (1, 1, 1)

        # 设置灯光
        if settings.importLight :
            print("========= 加载灯光设置 Loading... =========")

            light_col = bpy.data.collections.new("Lights")
            Arch_Col.children.link(light_col)
            light_xml = xml_root.find("./LightList")
            for x in light_xml.findall("./*"):
                L_Type = x.attrib["type"]
                light_name = "tmp_light_name"
                color = ConvertColor(x.attrib["color"])

                # print(x.attrib)
                if L_Type in ("AREA", "DISK"):
                    light_data = bpy.data.lights.new(name="Light", type = "AREA")
                else:
                    light_data = bpy.data.lights.new(name="Light", type = L_Type)

                light_obj = bpy.data.objects.new(light_name, light_data)
                light_obj.data.energy = float(x.attrib["multiplier"])
                light_obj.data.color = color[:-1]

                if L_Type == "POINT":
                    light_obj.data.shadow_soft_size = 0.005 if float(x.attrib["length"]) * fac < 0.005 else float(x.attrib["length"]) * fac
                elif L_Type == "AREA":
                    light_obj.data.shape = 'RECTANGLE'
                    light_obj.data.size = 0.005 if float(x.attrib["length"]) * fac < 0.005 else float(x.attrib["length"]) * fac
                    light_obj.data.size_y = 0.005 if float(x.attrib["width"]) * fac < 0.005 else float(x.attrib["width"]) * fac
                    light_obj.data.cycles.is_portal = True if x.attrib["portal"] == "true" else False
                elif L_Type == "DISK":
                    light_obj.data.shape = 'DISK'
                    light_obj.data.size = 0.005 if float(x.attrib["length"]) * fac < 0.005 else float(x.attrib["length"]) * fac
                    light_obj.data.size_y = 0.005 if float(x.attrib["width"]) * fac < 0.005 else float(x.attrib["width"]) * fac
                    light_obj.data.cycles.is_portal = True if x.attrib["portal"] == "true" else False
                elif L_Type == "SUN":
                    light_obj.data.angle = 0.005
                elif L_Type == "SPOT" :
                    pass
                
                for light in x.findall("./*") :
                    matrix = ConvertMatrix(light.attrib["matrix"])

                    light_instance = light_obj.copy()
                    light_instance.name = light.attrib["name"]
                    light_instance.matrix_world = matrix * fac
                    light_instance.scale *= 1 / fac

                    light_instance.visible_camera = True if light.attrib["invisible"] == "true" else False
                    light_instance.visible_diffuse = True if light.attrib["affectdiffuse"] == "true" else False
                    light_instance.visible_glossy = True if light.attrib["affectspecular"] == "true" else False
                    light_instance.visible_transmission = True if light.attrib["affectreflections"] == "true" else False
                    
                    light_col.objects.link(light_instance)
                
                #Delete Origin objects
                bpy.data.objects.remove(light_obj)

            print("========= 灯光设置完成 Ended =========")

        # 设置环境
        '''
        if settings.importEnvironment :
            print("========= 加载环境设置 Loading... =========")

            env_color = ConvertColor(xml_root.find("./Environment/Color").text)
            env_intensity = float(xml_root.find("./Environment/Multiplier").text)
            env_texmap = xml_root.find("./Environment/Texmap")

            scene = bpy.context.scene
            world = scene.world
            world.use_nodes = True
            nodes = world.node_tree.nodes
            links = world.node_tree.links

            # clear default nodes
            nodes.clear()

            # create input node
            world_output_node = nodes.new("ShaderNodeOutputWorld")
            world_output_node.location = (0, 0)

            backgroud_node = nodes.new("ShaderNodeBackground")
            backgroud_node.location = (-200, 0)
            backgroud_node.inputs[0].default_value = env_color
            backgroud_node.inputs[1].default_value = env_intensity

            links.new(backgroud_node.outputs[0], world_output_node.inputs[0])

            # create texmap node
            if env_texmap :                
                if env_texmap.attrib["Texmap"] != "undefined":
                    texmap_type = env_texmap.attrib["Texmap"].split(":")[-1]
                    CreateNode(nodes, links, env_texmap[0], backgroud_node.inputs[0], texmap_type)
                
            print("========= 环境设置完成 Ended =========")
        
        '''

        # 设置材质
        if settings.importMaterial :
            print("========= 加载材质 Loading... =========")
            SceneMaterials = [ m for m in bpy.data.materials[:] if not m.is_grease_pencil]
            
            Create_ColorCorrection()

            for mat in SceneMaterials:
                material_name = mat.name
                nodes = mat.node_tree.nodes
                links = mat.node_tree.links
                
                mat.blend_method = "CLIP"
                mat.shadow_method = "HASHED"

                m = xml_root.find("./MaterialList/*/[@name='%s']" % material_name)
                
                try:
                    nodes.clear()
                    outputShader = nodes.new("ShaderNodeOutputMaterial")
                    if hasattr(m, "tag"):
                        if m.tag == "DoubleSideMtl" :
                            DoubleMixShader = nodes.new("ShaderNodeMixShader")
                            links.new(DoubleMixShader.outputs["Shader"], outputShader.inputs["Surface"])
                            DoubleMixShader.location = (0, -150)
                            
                            frontMtl = m.attrib["frontmtl"].split(":")[0]
                            backMtl = m.attrib["backmtl"].split(":")[0]
                            
                            if frontMtl != "undefined" :
                                FMat = xml_root.find("./MaterialList/SingleMtl/[@name='%s']" % frontMtl)
                                node = CreateSingleMtl(nodes, links, FMat)
                                links.new(node.outputs["BSDF"], DoubleMixShader.inputs[1])
                            
                                if frontMtl == backMtl:
                                    links.new(node.outputs["BSDF"], DoubleMixShader.inputs[2])
                                else:
                                    if backMtl != "undefined" :
                                        back = xml_root.find("./MaterialList/SingleMtl/[@name='%s']" % backMtl)
                                        node = CreateSingleMtl(nodes, links, back)
                                        links.new(node.outputs["BSDF"], DoubleMixShader.inputs[2])
                            
                            translucency_color = ConvertColor(m.attrib["translucency"])
                            translucency_map = m.attrib["texmap_translucency"]
                            translucency_amount = m.attrib["texmap_translucency_multiplier"]

                            amount = colorsys.rgb_to_hsv(translucency_color[0], translucency_color[1], translucency_color[2])[2] * float(translucency_amount) / 100.0

                            DoubleMixShader.inputs["Fac"].default_value = amount * float(translucency_amount) / 100

                            if translucency_map != "undefined":
                                texmap_type = m.attrib["texmap_translucency"].split(":")[-1]
                                CreateNode(nodes, links, m[0], DoubleMixShader.inputs["Fac"], texmap_type)
                        
                        elif m.tag == "SingleMtl" :
                            node = CreateSingleMtl(nodes, links, m)
                            links.new(node.outputs["BSDF"], outputShader.inputs["Surface"])
                            
                            # BUMP
                            #
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
                except Exception as ex:
                    print(traceback.print_exc())
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
        version = "2022-08-30"

        # layout.prop(settings, "newfile")
        layout.label(text = "当前版本：" + version , icon='QUESTION')
        layout.label(text = "使用此插件前", icon='ERROR')
        layout.label(text = "建议新的空场景", icon='ERROR')
        layout.prop(settings, "importSetting", icon='PREFERENCES')
        layout.prop(settings, "importCamera", icon='CAMERA_DATA')
        layout.prop(settings, "importEnvironment", icon='WORLD_DATA')
        layout.prop(settings, "importLight", icon='LIGHT_DATA')
        layout.prop(settings, "importModel", icon='MESH_DATA')
        layout.prop(settings, "importProxy", icon='LINK_BLEND')
        layout.prop(settings, "importMaterial", icon='MATERIAL')

        row = layout.column(align=True)
        row.scale_y = 1.8
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