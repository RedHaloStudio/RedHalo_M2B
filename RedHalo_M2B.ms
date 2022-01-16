/*
 * @Author: RedHalo Studio 
 * @Date: 2022-01-15 16:47:04 
 * @Last Modified by: RedHaloStudio
 * @Last Modified time: 2022-01-15 21:45:52
 */

--Load the xml assembly
dotNet.loadAssembly "system.xml"
--Create an xml document object.
global xmlDoc = dotNetObject "system.xml.xmlDocument"
-- Create a root element for the xml doc and add it to the xmlDocument.
root = xmlDoc.createElement "RedHalo_Max_to_Blender_Convert"
xmlDoc.appendChild root

/*------------------------------------------------------
--------------------- GLOBAL VARS ----------------------
------------------------------------------------------*/
Material_List = #()

CR_DiffuseProps = #("colordiffuse", "texmapDiffuse")
DiffuseProps = #("Diffuse", "texmap_diffuse")
DiffuseAttrib = #("Color", "Texmap")

MetallicProps = #("reflection_metalness", "texmap_metalness")
MetallicAttrib = #("Amount", "Texmap")

CR_ReflectProps = #("colorreflect", "texmapReflect")
ReflectProps = #("Reflection",  "texmap_reflection")
ReflectAttrib = #("Amount", "Texmap")

RoughnessProps = #("reflection_Glossiness", "texmap_reflectionGlossiness")
RoughnessAttrib = #("Amount", "Texmap")

AnisotropyProps = #("anisotropy", "texmap_anisotropy")
AnisotropyAttrib = #("Amount", "Texmap")

AnisotropyRotationProps = #("anisotropy_rotation",  "texmap_anisotropy_rotation")
AnisotropyRotationAttrib = #("Amount", "Texmap")

SheenProps = #("sheen_color", "texmap_sheen")
SheenAttrib = #("Amount", "Texmap")

CoatProps = #("coat_amount", "texmap_coat_color")
CoatAttrib = #("Amount", "Texmap")

CoatRoughnessProps = #("coat_glossiness", "texmap_coat_glossiness")
CoatRoughnessAttrib = #("Amount", "Texmap")

IORProps = #( "reflection_ior", "texmap_reflectionior") --"refraction_ior", "texmap_refractionIOR", "texmap_reflectionior", "reflection_lockior")
IORAttrib = #("Amount", "Texmap")

RefractProps = #("Refraction", "texmap_refraction")
RefractAttrib = #("Amount", "Texmap")

RefractRoughnessProps = #("refraction_glossiness", "texmap_refractionGlossiness")
RefractRoughnessAttrib = #("Amount", "Texmap")

EmissionProps = #("selfIllumination", "texmap_self_illumination")
EmissionAttrib = #("Color", "Texmap")

EmissionStrengthProps = #("selfIllumination_multiplier", "texmap_self_illumination_multiplier")
EmissionStrengthAttrib = #("Amount", "Texmap")

OpacityProps = #("texmap_opacity")
OpacityAttrib = #("Texmap")

BumpProps = #("texmap_bump_multiplier", "texmap_bump")
BumpAttrib = #("Amount", "Texmap")

TranslucentProps = #("texmap_translucent")
TranslucentAttrib = #("Texmap")

DisplacementProps = #("texmap_displacement_multiplier", "texmap_displacement")
DisplacementAttrib = #("Amount", "Texmap")

BitmapProps = #("clipu", "clipv", "clipw", "cliph", "alphasource", "filename")
CoordsProps = #("U_Tile", "V_Tile", "U_Tiling", "V_Tiling", "U_Offset", "V_Offset", "W_Angle", "V_Angle", "U_Angle")

CheckerProps = #("color1", "color2", "map1", "map2", "map1Enabled", "map2Enabled")


-- Node Array ---
NodeArray = #("Diffuse", "Metallic", "Reflection", "Roughness", "Anisotropic", "AnisotropicRotation", "Sheen", "Coat", "CoatRoughness", "IOR", "Refraction", "RefractRoughness", "Emission", "EmissionStrength", "Opacity", "Bump", "Translucent", "Displacement")
-- NodeArray = #("Diffuse")
NodePropsArray = #(DiffuseProps, MetallicProps, ReflectProps, RoughnessProps, AnisotropyProps, AnisotropyRotationProps, SheenProps, CoatProps, CoatRoughnessProps, IORProps, RefractProps, RefractRoughnessProps, EmissionProps, EmissionStrengthProps, OpacityProps, BumpProps, TranslucentProps, DisplacementProps)
-- NodePropsArray = #(DiffuseProps)
AttribsArray = #(DiffuseAttrib, MetallicAttrib, ReflectAttrib, RoughnessAttrib, AnisotropyAttrib, AnisotropyRotationAttrib, SheenAttrib, CoatAttrib, CoatRoughnessAttrib, IORAttrib, RefractAttrib, RefractRoughnessAttrib, EmissionAttrib, EmissionStrengthAttrib, OpacityAttrib, BumpAttrib, TranslucentAttrib, DisplacementAttrib)


/*-- 可以转换的纹理类型
Bitmaptexture
Bricks
Checker
Color_Correction
Mix
RGB_Multiply
BerconTile
CompositeTexturemap
-----------------*/

/*------------------------------------------------------
--------------------------------------------------------
------------------------------------------------------*/

/*
-- Object List
for i in geometry do (
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
*/

---------Function BEGIN------------

fn ConvertGamma acolor gamma = (
    r = (acolor.r / 255.0) ^ gamma * 255
    g = (acolor.g / 255.0) ^ gamma * 255
    b = (acolor.b / 255.0) ^ gamma * 255
    
    return (color r g b)
)

fn CleanMeditSlot =
(
    for i = 1 to 24 do
    (
        if i < 10 then (
            _tmp = standard name:("0" + i as string +" - Default")
        )else(
            _tmp = standard name:(i as string +" - Default")
        )
        meditMaterials[i] = _tmp
    )
)

fn ChangeMtlType mat = (
    matType = classof mat
    case matType of (
        VRayOverrideMtl:(
            _t = mat.baseMtl
            replaceinstances mat _t
        )
        VRayBlendMtl1:(
            _t = mat.baseMtl
            replaceinstances mat _t
        )
        VrayMtlWrapper:(
            _t = mat.baseMtl
            replaceinstances mat _t
        )
    )
)

--整理场景中的纹理
fn simplyTex node = (
    try( nodeType = classof node ) catch ()

    case nodeType of
    (
        CompositeTexturemap:(
            return (simplyTex node.maplist[1])
        )
        Output: (
            return (simplyTex node.map1)
        )
        VRayNormalMap: (
            return (simplyTex node.normal_map)
        )
        VRayColor2Bump: (
            return (simplyTex node.map)
        )
        VRayTriplanarTex: (
            return (simplyTex node.texture)
        )
        CoronaColorCorrect: (
            return (simplyTex node.inputTexmap)
        )
        CoronaAO: (
            return (simplyTex node.colorUnoccluded)
        )
        CoronaNormal: (
            return (simplyTex node.normalMap)
        )
        Bitmaptexture: (
            return node
        )
        BlendedBoxMap: (
            return (simplyTwx node.tex[1])
        )
        Combustion:
            return undefined
        default:
            return node
    )	
)

--整理所有材质
fn simplyMat mat = (
    --整理场景材质
    matType = classof mat
    case matType of
    (
        VrayMtl:
        (
            if classof mat.texmap_diffuse == VrayColor do (
                gamma = mat.texmap_diffuse.color_gamma
                clr = mat.texmap_diffuse.color
                _c = ConvertGamma clr gamma

                mat.diffuse = _c
                mat.texmap_diffuse = undefined
            )

            if classof mat.texmap_diffuse == ColorMap do (
                gamma = mat.texmap_diffuse.gamma
                clr = mat.texmap_diffuse.SOLIDCOLOR
                _c = ConvertGamma clr gamma

                mat.diffuse = _C
                mat.texmap_diffuse = undefined
            )

            mat.texmap_diffuse = simplyTex mat.texmap_diffuse
            mat.texmap_reflection = simplyTex mat.texmap_reflection
            mat.texmap_reflectionGlossiness = simplyTex mat.texmap_reflectionGlossiness
            mat.texmap_refraction = simplyTex mat.texmap_refraction
            mat.texmap_refractionGlossiness = simplyTex mat.texmap_refractionGlossiness
            mat.texmap_metalness = simplyTex mat.texmap_metalness
            mat.texmap_refractionIOR  = simplyTex mat.texmap_refractionIOR 
            mat.texmap_opacity  = simplyTex mat.texmap_opacity 
            mat.texmap_bump = simplyTex mat.texmap_bump
            mat.texmap_self_illumination = simplyTex mat.texmap_self_illumination
        )
        Standardmaterial:
        (
            mat.diffuseMap = simplyTex mat.diffuseMap
            mat.reflectionMap = simplyTex mat.reflectionMap
            mat.refractionMap = simplyTex mat.refractionMap
            mat.glossinessMap = simplyTex mat.glossinessMap
            mat.bumpMap = simplyTex mat.bumpMap
            mat.opacityMap = simplyTex mat.opacityMap
        )
        CoronaMtl:
        (
            mat.texmapDiffuse = simplyTex mat.texmapDiffuse
            mat.texmapReflect = simplyTex mat.texmapReflect
            mat.texmapReflectGlossiness = simplyTex mat.texmapReflectGlossiness
            mat.texmapRefract = simplyTex mat.texmapRefract
            mat.texmapRefractGlossiness = simplyTex mat.texmapRefractGlossiness
            mat.texmapBump = simplyTex mat.texmapBump
            mat.texmapOpacity = simplyTex mat.texmapOpacity
            mat.texmapIor = simplyTex mat.texmapIor
            mat.texmapSelfIllum = simplyTex mat.texmapSelfIllum
        )
        VRayLightMtl:
        (
            mat.texmap = simplyTex mat.texmap
            mat.opacity_texmap = simplyTex mat.opacity_texmap
        )
        MultiMaterial:
        (
            for i = 1 to mat.numsubs do
            (
                simplyMat mat[i]
            )
        )
    )
)

------- Bitmap Node BEGIN  ------------
/*
*ParentNode 父级节点
*Bitmaptexture 子属性
*/
fn CreateBitmapNode ParentNode Bitmaptexture = (

    BitmapItemNode = xmlDoc.createElement "Bitmap"
    parentNode.appendChild BitmapItemNode

    for o in bitmapProps do (
        BitmapItemNode.setAttribute o ((getProperty Bitmaptexture o) as string)
    )
    
    FilenameNode = xmlDoc.CreateElement "Filename"
    bitmapItemNode.appendChild FilenameNode
    filename = getProperty Bitmaptexture "filename"
    if  filename != "undefined" do (
        FilenameNode.InnerText = filename
    )

    /*
    *  图片裁切，重复数量
    */
    bitmapCoords = getProperty Bitmaptexture "Coords"
    for o in CoordsProps do (
        BitmapItemNode.setAttribute o ((getProperty bitmapCoords o) as string)
    )
)
------- Bitmap Node END ---------------

/*
Create All element
*/
fn CreateElement ParentNode Texture = (
    /*
    ### ParentNode
    */
    TextureType = ClassOf Texture
    case TextureType of (
        Bitmaptexture:(
            CreateBitmapNode ParentNode Texture
        )
        Bricks:(
            BrickNode = xmlDoc.CreateElement "Brick_Texture"
            ParentNode.appendChild BrickNode

            --设置 Tiles平铺 参数
            -- Tiles的所有参数，实际用不到这么多，因此需要自建数组
            -- BrickParams = getPropNames Texture
            BrickParams = #("Mortar_Map", "Bricks_Map", "Brick_color", "Tile_Type", "Mortar_color", "Horizontal_Count", "Vertical_Count", "Horizontal_Gap", "Line_Shift")

            for p in BrickParams do (
                params = getProperty Texture p
                BrickNode.setAttribute p (params as string)
            )

            -- 添加 Tiles的重复坐标和旋转参数
            Coords = getProperty Texture "Coords"
            for o in CoordsProps do (
                BrickNode.setAttribute o ((getProperty Coords o) as string)
            )

            MortarNode = xmlDoc.CreateElement "Mortar_Map"
            BrickNode.appendChild MortarNode

            TileNode = xmlDoc.CreateElement "Tiles_Map"
            BrickNode.appendChild TileNode

            tex_Mortar = getProperty Texture "Mortar_Map"
            CreateElement MortarNode tex_Mortar

            tex_Tile = getProperty Texture "Bricks_Map"
            CreateElement TileNode tex_Tile

        )
        Checker:(
            CheckerNode = xmlDoc.CreateElement "Checker"
            ParentNode.appendChild CheckerNode

            --- 所有Checker参数
            --- getPropNames Texture
            -- CheckerParams = #("Soften", "color1", "color2", "map1", "map2", "map1Enabled", "map2Enabled", "coords")
            CheckerParams = #("color1", "color2", "map1", "map2", "map1Enabled", "map2Enabled")

            for p in CheckerParams do (
                attribute = getProperty Texture p
                CheckerNode.setAttribute p (attribute as string)
            )
            
            -- 平铺和旋转参数
            Coords = getProperty Texture "Coords"

            for c in CoordsProps do (
                CheckerNode.setAttribute c ((getProperty Coords c) as string)
            )

            CheckerMap1Node = xmlDoc.CreateElement "Checker_Map1"
            CheckerNode.appendChild CheckerMap1Node

            Map1 = getProperty Texture "map1"
            CreateElement CheckerMap1Node Map1

            CheckerMap2Node = xmlDoc.CreateElement "Checker_Map2"
            CheckerNode.appendChild CheckerMap2Node
            Map2 = getProperty Texture "map2"
            CreateElement CheckerMap2Node Map2
        )
        Mix:(
            MixNode = xmlDoc.CreateElement "Mix"
            ParentNode.appendChild MixNode

            -- Mix参数组
            -- getPropNames Texture
            -- MixParams = #("mixAmount", "lower", "upper", "useCurve", "color1", "color2", "map1", "map2", "Mask", "map1Enabled", "map2Enabled", "maskEnabled", "output")
            MixParams = #("mixAmount", "color1", "color2", "map1", "map2", "Mask", "map1Enabled", "map2Enabled", "maskEnabled")
            for p in MixParams do (
                att = getProperty Texture p
                MixNode.setAttribute p (att as string)
            )

            Map1Node = xmlDoc.CreateElement "Map1"
            MixNode.appendChild Map1Node
            Map1 = getProperty Texture "map1"
            CreateElement Map1Node Map1

            Map2Node = xmlDoc.CreateElement "Map2"
            MixNode.appendChild Map2Node
            Map2 = getProperty Texture "map2"
            CreateElement Map2Node Map2

            MaskNode = xmlDoc.CreateElement "Mask"
            MixNode.appendChild MaskNode

            MaskMap = getProperty Texture "Mask"
            CreateElement MaskNode MaskMap

        )
        Falloff:(
            FalloffNode = xmlDoc.CreateElement "Falloff"
            ParentNode.appendChild FalloffNode

            -- FalloffParams = #("color1", "map1Amount", "map1", "map1on", "color2", "map2Amount", "map2", "map2on", "type", "direction", "node", "mtlIOROverride", "ior", "extrapolateOn", "nearDistance", "farDistance")
            FalloffParams = #("color1", "map1Amount", "map1", "color2", "map2Amount", "map2", "map2on", "type", "ior")
            for i in FalloffParams do (
                atts = getProperty Texture i
                FalloffNode.setAttribute i (atts as string)
            )

            map1Node = xmlDoc.CreateElement "map1"
            FalloffNode.appendChild map1Node
            map1 = getProperty Texture "map1"
            CreateElement map1Node map1

            map2Node = xmlDoc.CreateElement "map2"
            FalloffNode.appendChild map2Node
            map2 = getProperty Texture "map2"
            CreateElement map2Node map2

        )
        Color_Correction:(
            /*
            color,map,
            rewireMode,rewireR,rewireG,rewireB,rewireA,
            HUESHIFT,
            saturation,
            tint,tintStrength,
            LIGHTNESSMODE,contrast,
            BRIGHTNESS,
            exposureMode,
            enableR,enableG,enableB,
            GAINRGB,gainR,gainG,gainB,
            GAMMARGB,gammaR,gammaG,gammaB,
            pivotRGB,pivotR,pivotG,pivotB,
            liftRGB,liftR,liftG,liftB,printerLights
            */

            CCNode = xmlDoc.CreateElement "ColorCorrection"
            ParentNode.appendChild CCNode

            CCParams = #("color", "map", "rewireMode", "HUESHIFT", "saturation", "LIGHTNESSMODE", "BRIGHTNESS", "contrast")
            -- CCParams = getPropNames Color_Correction
            for i in CCParams do (
                atts = getProperty Texture i
                CCNode.setAttribute i (atts as string)s
            )

            map = getProperty Texture "map"
            CreateElement CCNode map
        )
        RGB_Multiply:(
            RGBMultNode = xmlDoc.CreateElement "RGBMultiply"

            Params = #("color1", "color2", "map1", "map2", "map1Enabled", "map2Enabled", "alphaFrom")
            ParentNode.appendChild RGBMultNode

            for p in Params do (
                att = getProperty texture p
                RGBMultNode.setAttribute p (att as string)
            )

            Map1Node = xmlDoc.CreateElement "Map1"
            RGBMultNode.appendChild Map1Node
            Map1 = getProperty Texture "map1"
            CreateElement Map1Node Map1
            
            Map2Node = xmlDoc.CreateElement "Map2"
            RGBMultNode.appendChild Map2Node
            Map2 = getProperty Texture "map2"
            CreateElement Map2Node Map2
        )
        Gradient:(
            Params = #("color1", "color2", "color3", "color2Pos", "gradientType")

            GradientNode = xmlDoc.CreateElement "Gradient"
            ParentNode.appendChild GradientNode

            for p in Params do (
                att = getProperty Texture p
                GradientNode.setAttribute p (att as string)
            )

            -- 添加 Tiles的重复坐标和旋转参数
            Coords = getProperty Texture "Coords"
            for o in CoordsProps do (
                GradientNode.setAttribute o ((getProperty Coords o) as string)
            )
        )
        VrayDirt:(
            params =# ("radius", "occluded_color", "unoccluded_color", "subdivs", "mode", "consider_same_object_only", "texmap_radius", "texmap_radius_multiplier", "texmap_occluded_color", "texmap_occluded_color_multiplier", "texmap_unoccluded_color", "texmap_unoccluded_color_multiplier")

            AONode = xmlDoc.CreateElement "AO"
            ParentNode.appendChild AONode

            for p in params do (
                att = getProperty texture p
                AONode.setAttribute p (att as string)
            )

            OccludedNode = xmlDoc.CreateElement "Occluded" --getProperty texture "texmap_occluded_color"
            UnoccludedNode = xmlDoc.CreateElement "Unoccluded"
            RadiusNode = xmlDoc.CreateElement "Radius"

            AONode.appendChild OccludedNode
            OccludedMap = getProperty texture "texmap_occluded_color"
            CreateElement OccludedNode OccludedMap

            AONode.appendChild UnoccludedNode
            UnoccludedMap = getProperty texture "texmap_unoccluded_color"
            CreateElement UnoccludedNode UnoccludedMap

            AONode.appendChild RadiusNode
            RadiusMap = getProperty texture "texmap_radius"
            CreateElement RadiusNode RadiusMap

        )
        VrayBump2Normal:(
            params = #("bump_map", "bump_map_mult", "mode", "map_channel")

            NormalNode = xmlDoc.CreateElement "Normal"
            ParentNode.appendChild NormalNode

            for p in params do (
                att = getProperty texture p
                NormalNode.setAttribute p (att as string)
            )

            MapNode = xmlDoc.CreateElement "Map"
            NormalNode.appendChild MapNode
            Map = getProperty  texture "bump_map"
            CreateElement MapNode map
        )
        /*
        Gradient_Ramp:(
            --Params = #(size, phase, amount, Gradient_Type, Noise_Type, Low_Threshold, High_Threshold, Source_Map_On, Threshold_Smoothing, levels)

        )
        BerconTile
        CompositeTexturemap
        */
    )
)

-------------------------
--- 处理重名材质名字
--- Unique Material Name
fn MakeUniqueMaterialName =(
    SingleMtlList = #()
    for cls in material.classes do (
        for i in getClassInstances cls do (
            index = findItem SingleMtlList i.name
            
            rec = appendIfUnique SingleMtlList i.name
            if not rec do (
                newName = i.name + "_RH_" + timeStamp() as string
                appendIfUnique SingleMtlList newName
                i.name = newName
            )
        )
    )
)
--处理重名材质结束
-----------------------

/*-------------------------------------
---------- FUNCTION END ---------------
-------------------------------------*/

/*
*    UI
*/
try(DestroyDialog M2B) catch()

xmlname = "RH_M2B.xml"
fbxname = "RH_M2B.fbx"
filepath = sysInfo.tempdir

rollout M2B "Export Blender"
(
    local RedHalo_Exp_SmoothGroup = true
    local RedHalo_Exp_Animation = false
    local RedHalo_Exp_Cameras = false
    local RedHalo_Exp_Lights = false

    groupBox gb1 "导出选项" width:190 height:75 pos:[5,5]
    radiobuttons rb_export_mode "" labels:#("整个场景", "选择物体") pos:[20,20]
    checkbutton cb_export_Object "代理物体" checked:true width:60 pos:[10,45] enabled:false
    checkbutton cb_export_Camera "相机" checked:true width:60 pos:[70,45] enabled:false
    checkbutton cb_export_Light "灯光"  checked:true width:60 pos:[130,45] enabled:false

    groupBox gb2 "模型选项" width:190 height:70 pos:[5, 85] enabled:false
    checkbutton cb_m_fbx_smoothGroup "Smoothing Groups" checked:true height:20 width:170 pos:[15, 100] enabled:false
    -- checkbutton cb_m_fbx_camera "Camera" checked:true height:20 width:170 pos:[15, 120] enabled:false
    -- checkbutton cb_m_fbx_Lights "Lights" checked:true height:20 width:170 pos:[15, 140] enabled:false
    checkbutton cb_m_fbx_Animation "Animation" checked:true height:20 width:170 pos:[15, 120] enabled:false
    -- checkbutton cb_m_fbx_ConvertUnit "Convert Unit" checked:true height:20 width:170 pos:[15, 180] enabled:false 
    
    groupbox gb3 "导出文件位置" width:190 height:40 pos:[5, 160]
    edittext et_file "" width:165 pos:[5, 182]
    button btn_file "..." width:20 height:20 pos:[170, 180]

    button btn_export "导出" width:155 height:30 pos:[10,210]
    button btn_about "?" width:30 height:30 pos:[165, 210]

    label lbl_right "(C)RedHalo Studio 发霉的红地蛋"

    on btn_about pressed do (
        messageBox "此版本编译于2022-01-14\n此版本限制：仅支持Vray英文版，不支持汉化版本\n其它材质不会导出，因此Blender加载后为空白节点\n支持材质类型：VrayMtl(Vray标准材质), Vray双面材质\n支持纹理类型: 标准贴图，平铺"
    )

    on btn_export pressed do (
        -- Global Setting
        SettingElement = xmlDoc.CreateElement "Setting"
        root.appendChild SettingElement

        RenderElement = xmlDoc.CreateElement "Renderer"
        SettingElement.appendChild RenderElement
        RenderElement.innerText = (filterString (renderers.current as string) ":")[1]

        GammaElement = xmlDoc.CreateElement "Gamma"
        SettingElement.appendChild GammaElement
        GammaElement.innerText = FileInGamma as string

        WidthElement = xmlDoc.CreateElement "Width"
        SettingElement.appendChild WidthElement
        WidthElement.innerText = renderWidth as string

        HeightElement = xmlDoc.CreateElement "Height"
        SettingElement.appendChild HeightElement
        HeightElement.innerText = renderHeight as string

        -- NodeListElement = xmlDoc.createElement "NodeList"
        -- root.appendChild NodeListElement

        CameraListElement = xmlDoc.createElement "CameraList"
        root.appendChild CameraListElement

        LightListElement = xmlDoc.createElement "LightList"
        root.appendChild LightListElement

        MaterialList = xmlDoc.createElement "MaterialList"
        root.appendChild MaterialList

        -- Lights List
        for i in Lights do (
            if classof i != Targetobject do (
                name = i.name
                matrix = i.transform

                LightsList = xmlDoc.CreateElement "Light"
                LightsList.setAttribute "name" name
                LightsList.setAttribute "matrix" (matrix as string)
                LightsList.setAttribute "type" "type"

                LightListElement.appendChild LightsList
            )
        )

        -- Camera List
        for i in Cameras do (
            if classof i != TargetObject do (
                name = i.name
                fov = i.fov as string
                matrix = i.transform

                cameraList = xmlDoc.createElement "Camera"
                cameraList.setAttribute "name" name
                cameraList.setAttribute "fov" fov
                cameraList.setAttribute "matrix" (matrix as string)
                CameraListElement.appendChild cameraList
            )
        )

        for i in sceneMaterials do (
            ChangeMtlType i
            simplyMat i
        )
        saveNodes #() (filepath + "rh-empty.max")

        -- 清理材质管理器
        CleanMeditSlot()
        -- 处理重名材质
        MakeUniqueMaterialName()
        
        --------------------------------
        ------ 复合材质列表
        -- Vray2SidedMtl List
        for i in getClassInstances VRay2SidedMtl do (
            SideMtl = xmlDoc.createElement "DoubleSideMtl"

            MaterialList.appendChild sideMtl

            sideMtl.setAttribute "name" i.name
            for p in (getPropNames i) do (
                att = getProperty i p
                sideMtl.setAttribute p (att as string)

                CreateElement sideMtl att
            )
        )

        -- VrayOverrideMtl List
        for i in getClassInstances VrayOverrideMtl do (
            OverrideMtl = xmlDoc.createElement "OverrideMtl"
            MaterialList.appendChild OverrideMtl
            -- VrayOverrideMtl, baseMtl, baseMtl_on, giMtl, gimtl_on, reflectMtl, reflectmtl_on, refractMtl, refractmtl_on, shadowMtl, shadowMtl_on
            -- CoronaRaySwitchMtl giMtl, reflectMtl, refractMtl, directMtl, displacementSource, viewportSource
            OverrideMtl.setAttribute "name" i.name

            for p in getPropNames i do (
                att = getProperty i p
                OverrideMtl.setAttribute p (att as string)
            )
        )
        -----复合材质列表 结束
        -----------------------

        --------------------------------
        ------ 基础材质节点列表
        -- VrayMtl List
        for i in getClassInstances VrayMtl do (
            SingleMtl = xmlDoc.createElement "SingleMtl"
            MaterialList.appendChild singleMtl

            SingleMtl.setAttribute "name" i.name

            -- VRayProps = #("brdf_useRoughness")
            useRoughness = getProperty i "brdf_useRoughness"
            SingleMtl.setAttribute "useRoughness" (useRoughness as string)

            for idx = 1 to NodeArray.count do (
                propName = NodeArray[idx]

                _node = xmlDoc.CreateElement propName
                SingleMtl.appendChild _node

                PropsArray = NodePropsArray[idx]
                AttribArray = AttribsArray[idx]

                num = 0
                
                for prop in PropsArray do (
                    num += 1
                    value = ""
                    texture = getProperty i prop
                    value = texture as string
                    
                    if (prop == "Reflection") or (prop == "Refraction") or (prop == "sheen_color") do (
                        value = (texture.v / 255.0) as string                        
                    )
                    _node.setAttribute AttribArray[num] value
                    
                    CreateElement _node texture
                )
            )
        )

        for i in getClassInstances VrayLightMtl do (
            LightMtl = xmlDoc.CreateElement "LightMtl"
            MaterialList.appendChild LightMtl
            LightMtl.setAttribute "name" i.name

            --VrayLightProps = #( "color" ,"multiplier" ,"texmap" ,"texmap_on" ,"twoSided" ,"compensate_exposure" ,"opacity_multiplycolor" ,"opacity_texmap" ,"opacity_texmap_on" ,"directLight_on" ,"directLight_subdivs" ,"directLight_cutoffThreshold" ,"displacement_multiplier" ,"displacement_texmap" ,"displacement_texmap_on" ,"texmap_resolution" ,"texmap_adaptiveness"
            VrayLightProps = #( "color" ,"multiplier" ,"texmap" ,"texmap_on" ,"twoSided" , "opacity_multiplycolor" ,"opacity_texmap" ,"opacity_texmap_on")

            --for idx = 1 to NodeArray.count do (
            for p in VrayLightProps do (
                att = getProperty i p
                LightMtl.setAttribute p (att as string)
                
            )

            LightMap = xmlDoc.CreateElement "Lightmap"
            LightMtl.appendChild Lightmap
            tex = getProperty i "texmap" 
            CreateElement LightMap tex

            OpacityMap = xmlDoc.CreateElement "Opacitymap"
            LightMtl.appendChild OpacityMap
            tex = getProperty i "opacity_texmap"
            CreateElement OpacityMap tex
            
        )
        
        xmlDoc.Save (filepath + xmlname)
        xmlDoc.Save ("D:\\xml_Temp.xml")

        --------FBX EXPORT-----
        pluginManager.loadClass FBXEXP
        --Geometry------------------------------------------------------------------------
        FBXExporterSetParam "SmoothingGroups" RedHalo_Exp_SmoothGroup
        FBXExporterSetParam "NormalsPerPoly" false
        FBXExporterSetParam "TangentSpaceExport" true
        FBXExporterSetParam "SmoothMeshExport" false
        FBXExporterSetParam "Preserveinstances" false
        FBXExporterSetParam "SelectionSetExport" false
        FBXExporterSetParam "GeomAsBone" false
        FBXExporterSetParam "ColladaTriangulate" true
        FBXExporterSetParam "PreserveEdgeOrientation" false
        --Animation------------------------------------------------------------------------
        FBXExporterSetParam "Animation" RedHalo_Exp_Animation
        --Cameras------------------------------------------------------------------------
        FBXExporterSetParam "Cameras" RedHalo_Exp_Cameras
        --Lights------------------------------------------------------------------------
        FBXExporterSetParam "Lights" RedHalo_Exp_Lights
        --Embed Media--------------------------------------------------------------------
        FBXExporterSetParam "EmbedTextures" false
        --Units----------------------------------------------------------------------------
        -- FBXExporterSetParam "ConvertUnit" BMAX_Exp_ConvertUnits
        -- FBXExporterSetParam "ScaleFactor" BMAX_Exp_GlobalScale
        --Axis Conversion-----------------------------------------------------------------
        FBXExporterSetParam "AxisConversionMethod" "None"
        FBXExporterSetParam "UpAxis" "Z"
        --UI----------------------------------------------------------------
        FBXExporterSetParam "ShowWarnings" false
        FBXExporterSetParam "GenerateLog" false
        --FBX File Format----------------------------------------------------------------
        FBXExporterSetParam "ASCII" false
        if  MaxVer < 14000 then 
        (
            FBXExporterSetParam "FileVersion" "FBX200600"
        )		
        else 
            (
                case MaxVer of 
                (
                    -- 3dsmax2018
                    20000: (
                            FBXExporterSetParam "FileVersion" "FBX201800"
                            )
                    -- 3dsmax2017
                    19000: (
                            FBXExporterSetParam "FileVersion" "FBX201700"
                            )
                    -- 3dsmax2016
                    18000: (
                            FBXExporterSetParam "FileVersion" "FBX201600"
                            )
                    -- 3dsmax2015
                    17000: (
                            FBXExporterSetParam "FileVersion" "FBX201500"
                            )
                    -- 3dsmax2014
                    16000: (
                            FBXExporterSetParam "FileVersion" "FBX201400"
                            )
                    -- 3dsmax2013
                    15000: (
                            FBXExporterSetParam "FileVersion" "FBX201300"
                            )
                    -- 3dsmax2012
                    14000: (
                            FBXExporterSetParam "FileVersion" "FBX201200"
                            )				
                )		
            )
        -----------------------------------------------------------------------------------	
        fbx = filepath + fbxname
        exportMode = rb_export_mode.state
        -- print exportMode
        if exportMode > 1 then (
            exportFile fbx #noPrompt selectedOnly:true	usage:FBXEXP
        )else(
            exportFile fbx #noPrompt selectedOnly:false	usage:FBXEXP
        )
        
    )
)

createDialog M2B width:200 pos:[1500,50]