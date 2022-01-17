bl_info = {  
    "name": "REDHALO_IMPORT_MTL",  
    "author": "Red Halo Studio",  
    "version": (0, 1),  
    "blender": (2, 80, 0),  
    "location": "View 3D > Tools > Red Halo Tools",  
    "description": "导入3ds Max材质",  
    "wiki_url": "",  
    "tracker_url": "",  
    "category": "Tools"
 }

from math import pi
import bpy
import bpy_extras
from bpy.types import Operator 
import colorsys
import tempfile
import os
from mathutils import Matrix
from xml.etree import ElementTree as xml

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
        
        ImageShader = CreateImageNode(nodes, links, bitmap_path, -900, -150, position=(uOffset, vOffset, 0), rotation=(uAngle, vAngle, wAngle), scale=(uTile, vTile, 1))        
        links.new(ImageShader.outputs["Color"], ParentNode)
    
    # 平铺 已完成
    elif texmap_type == "Tiles" :
        # BrickNode = texmap.findall("./")

        BrickShader = nodes.new("ShaderNodeTexBrick")
        BrickShader.location = (-600, 0)
        links.new(BrickShader.outputs["Color"], ParentNode)

        # 平铺纹理基础参数设置
        Brick_Color = texmap.attrib["Brick_color"]
        Mortar_Color = texmap.attrib["Mortar_color"]
        BrickShader.inputs["Color1"].default_value = ConvertColor(Brick_Color)
        BrickShader.inputs["Color2"].default_value = ConvertColor(Brick_Color)
        BrickShader.inputs["Mortar"].default_value = ConvertColor(Mortar_Color)

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
        MixShader.inputs["Fac"].default_value = float(amount)
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
        if texmap.attrib["map2"] != "undefinded":
            map2Node = _node[1][0]
            map2Type = texmap.attrib["map2"].split(":")[-1]
            CreateNode(nodes, links, map2Node, MixRGBShader.inputs["Color2"], map2Type)

        Falloff_Type = texmap.attrib["type"]
        if Falloff_Type == "2":
            FresnelShader = nodes.new("ShaderNodeFresnel")
            links.new(FresnelShader.outputs["Fac"], MixRGBShader.inputs["Fac"])

            FresnelShader.inputs["IOR"].default_value = float(texmap.attrib["ior"])

    # 颜色校正节点 已完成
    elif texmap_type == "Color Correction":
        BCShader = nodes.new("ShaderNodeBrightContrast")
        HueShader = nodes.new("ShaderNodeHueSaturation")
        InvertShader = nodes.new("ShaderNodeInvert")
        GammaShader = nodes.new("ShaderNodeGamma")

        links.new(BCShader.outputs["Color"], HueShader.inputs["Color"])
        links.new(HueShader.outputs["Color"], InvertShader.inputs["Color"])
        links.new(InvertShader.outputs["Color"], GammaShader.inputs["Color"])
        links.new(GammaShader.outputs["Color"], ParentNode)

        InvertShader.inputs["Fac"].default_value = 0

        BCShader.inputs["Color"].default_value = ConvertColor(texmap.attrib["color"])

        if texmap.attrib["rewireMode"] == "1":
            HueShader.inputs["Saturation"].default_value = 0
        elif texmap.attrib["rewireMode"] == "2":
            InvertShader.inputs["Fac"].default_value = 1

        if texmap.attrib["LIGHTNESSMODE"] == "0":
            BCShader.inputs["Bright"].default_value = float(texmap.attrib["BRIGHTNESS"])/100.0
            BCShader.inputs["Contrast"].default_value = float(texmap.attrib["contrast"])/100.0

        # HUE Shift
        HueShader.inputs["Hue"].default_value = float(texmap.attrib["HUESHIFT"])/360.0 + 0.5
        HueShader.inputs["Saturation"].default_value = float(texmap.attrib["saturation"])/200.0 + 0.5

        if texmap.attrib["map"] != "undefined" :
            mapNode = _node[0]
            mapType = texmap.attrib["map"].split(":")[-1]
            CreateNode(nodes, links, mapNode, BCShader.inputs["Color"], mapType)

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
    # VrayBitmap
    elif texmap_type == "VrayBitmap" :
        pass
    # VrayBump2Normal
    # VrayCompTex
    # VrayEdgeTex
    # VrayNormalMap
    # VrayAO
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
            CreateNode(nodes, links, RadiusMap, AONode.inputs["Radius"], RadiusType)

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
    TextureClass = ("Bitmap", "Tiles", "Mix", "Falloff", "Color Correction", "RGB Multiply", "Gradient", "VRayDirt")

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
        
        elif path in ("Metallic", "Reflection", "Roughness", "Anisotropic", "AnisotropicRotation", "Coat", "CoatRoughness", "IOR", "Refraction", "RefractRoughness", "EmissionStrength", "Bump", "Displacement") :
            value = float(node.attrib["Amount"])
            if path == "Roughness" and useRoughness == "false":
                bsdfShader.inputs[input].default_value = 1 - value

                if texmap_type in TextureClass :
                    InvertNode = nodes.new("ShaderNodeInvert")
                    links.new(InvertNode.outputs["Color"], bsdfShader.inputs[input])
                    CreateNode(nodes, links, texmap_node, InvertNode.inputs["Color"], texmap_type)
            elif path == "Bump" :
                if texmap_type in TextureClass :
                    bumpShader = nodes.new("ShaderNodeBump")
                    bumpShader.inputs["Strength"].default_value = 0.1
                    links.new(bumpShader.outputs["Normal"], bsdfShader.inputs["Normal"])
                    CreateNode(nodes, links, texmap_node, bumpShader.inputs["Height"], texmap_type)
            elif path in ("Translucent", "Displacement") :
                pass
            else:
                bsdfShader.inputs[input].default_value = value
                if texmap_type in TextureClass :
                    CreateNode(nodes, links, texmap_node, bsdfShader.inputs[input], texmap_type)

    return bsdfShader

class Tools_OT_Max2Blender(Operator):
    bl_idname = "redhalo.maxtoblender"
    bl_label = "Import Max Scene"
    bl_description = "Import Max Scene"
    bl_options = {'REGISTER', 'UNDO'} 

    def execute(self, context): 
        MTLFile = tempfile.gettempdir() + "\\RH_M2B.xml"
        xml_file = xml.parse(MTLFile)
        xml_root = xml_file.getroot()

        # 加载模型
        print("加载模型Loading...")
        FBXFile = tempfile.gettempdir() + "\\RH_M2B.fbx"
        # Load FBX Scene
        bpy.ops.import_scene.fbx(filepath=FBXFile)

        print("模型加载完成 Ended")

        # 设置场景
        renderWidth = float(xml_root.find("./Setting/Width").text)
        renderHeight = float(xml_root.find("./Setting/Height").text)
        bpy.context.scene.render.resolution_x = renderWidth
        bpy.context.scene.render.resolution_y = renderHeight

        # 设置相机
        camera_xml = xml_root.find("./CameraList")
        for c in camera_xml.findall("./*") :
            camera_name = c.attrib["name"]
            camera_matrix = ConvertMatrix(c.attrib["matrix"])
            camera_fov = c.attrib["fov"]
            # camera_near = c.attrib["near"]
            # camera_far = c.attrib["far"]

            camera_data = bpy.data.cameras.new(name='Camera')
            camera_object = bpy.data.objects.new(camera_name, camera_data)
            bpy.context.scene.collection.objects.link(camera_object)
            camera_object.data.angle = float(camera_fov)/180 * pi
            camera_object.matrix_world = camera_matrix

        # 设置灯光
        print("加载灯光设置 Loading...")
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
                light_obj.data.size = float(x.attrib["length"])
                light_obj.data.size_y = float(x.attrib["width"])
                light_obj.data.cycles.is_portal = True if x.attrib["portal"] == "true" else False
            elif L_Type == "DISK":
                light_obj.data.shape = 'DISK'
                light_obj.data.size = float(x.attrib["length"])
                light_obj.data.size_y = float(x.attrib["width"])
                light_obj.data.cycles.is_portal = True if x.attrib["portal"] == "true" else False
            elif L_Type == "SUN":
                light_obj.data.angle = 0.01

            bpy.context.scene.collection.objects.link(light_obj)

            light_obj.matrix_world = matrix

            light_obj.visible_camera = True if x.attrib["invisible"] == "true" else False
            light_obj.visible_diffuse = True if x.attrib["affectdiffuse"] == "true" else False
            light_obj.visible_glossy = True if x.attrib["affectspecular"] == "true" else False
            light_obj.visible_transmission = True if x.attrib["affectreflections"] == "true" else False

        print("灯光设置完毕 Ended")

        # 设置材质
        print("加载材质 Loading... ")
        SceneMaterials = [ m for m in bpy.data.materials[:] if not m.is_grease_pencil]
        m_mat = xml_root.find("./MaterialList/")

        for mat in SceneMaterials:
            material_name = mat.name
            nodes = mat.node_tree.nodes
            links = mat.node_tree.links
            
            nodes.clear()
            outputShader = nodes.new("ShaderNodeOutputMaterial")

            m = xml_root.find("./MaterialList/*/[@name='%s']" % material_name)

            print(material_name)

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
                
                mix2SideShader = nodes.new("ShaderNodeMixShader")
                mixTransShader = nodes.new("ShaderNodeMixShader")
                TransparentShader = nodes.new("ShaderNodeBsdfTransparent")
                GeometryShader = nodes.new("ShaderNodeNewGeometry")
                MathShader = nodes.new("ShaderNodeMath")

                links.new(GeometryShader.outputs["Backfacing"], MathShader.inputs[0])
                links.new(MathShader.outputs["Value"], mix2SideShader.inputs["Fac"])
                links.new(emissionShader.outputs["Emission"], mix2SideShader.inputs[1])
                links.new(mix2SideShader.outputs["Shader"], mixTransShader.inputs[2])
                links.new(TransparentShader.outputs["BSDF"], mix2SideShader.inputs[2])
                links.new(TransparentShader.outputs["BSDF"], mixTransShader.inputs[1])
                links.new(mixTransShader.outputs["Shader"], outputShader.inputs["Surface"])

                emissionShader.location = (-750, 0)
                mixTransShader.location = (-250, 0)
                mix2SideShader.location = (-500, 0)
                MathShader.location = (-750, 200)
                GeometryShader.location = (-1000, 300)
                TransparentShader.location = (-750, -200)

                # 设置参数
                emissionShader.inputs["Color"].default_value = ConvertColor(m.attrib["color"])
                emissionShader.inputs["Strength"].default_value = float(m.attrib["multiplier"])

                mixTransShader.inputs["Fac"].default_value = 0
                MathShader.operation = 'MULTIPLY'
                if m.attrib["twoSided"] == "false":
                    MathShader.inputs[1].default_value = 0
                else :
                    MathShader.inputs[1].default_value = 1

                if m.attrib["texmap"] != "undefined":                            
                    texmap_type = m.attrib["texmap"].split(":")[-1]
                    CreateNode(nodes, links, m[0][0], emissionShader.inputs["Color"], texmap_type)
                
                if m.attrib["opacity_texmap"] != "undefined" :
                    texmap_type = m.attrib["texmap"].split(":")[-1]
                    CreateNode(nodes, links, m[1][0], mixTransShader.inputs["Fac"], texmap_type)

            elif m.tag == "OverrideMtl" :

                pass

        return {'FINISHED'}

class VIEW3D_PT_RedHaloM3B(bpy.types.Panel):
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'RedHalo'    
    bl_label = "REDHALO Max to Blender"

    def draw(self, context):              
        layout = self.layout
        row = layout.column(align=True)
        row.scale_y = 1.5
        row.operator('redhalo.maxtoblender', icon='IMPORT',text = "Max to Blender")

classes = (
    Tools_OT_Max2Blender,
    VIEW3D_PT_RedHaloM3B
)

def register():
    for cls in classes:
        bpy.utils.register_class(cls)

def unregister():
    for cls in reversed(classes):
        bpy.utils.unregister_class(cls)