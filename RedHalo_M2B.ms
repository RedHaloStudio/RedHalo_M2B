/*
 * @Author: RedHalo Studio 
 * @Date: 2022-03-28 22:31:04 
 * @Last Modified by: RedHaloStudio
 * @Last Modified time: 2022-03-28 22:38:55
 */

 --macroScript RedHalo_Tools
 --category:"Red Halo"
 --toolTip:"Red Halo Export2Blender"
(
    _version = "0.3"
    _author = "RedHalo Studio(发霉的红地蛋)"
    _data = "2022-03-30"
    _copyright = "(c) 2022 RedHalo Studio. All rights reserved."
    _title = "RedHalo Max2Blender"

    -- 获取场景中所有材质，包括子材质。
    function GetSceneMaterials = 
    (
        AllSceneMaterialsName = #()
        AllSceneMaterials = #()
        for cls in material.classes do (
            for i in getClassInstances cls do (
                usedMaterial = false
                for m in refs.dependents i do (		
                    if superclassof m == GeometryClass do (
                        usedMaterial = true
                        break
                    )
                )

                if usedMaterial do (
                    if appendIfUnique AllSceneMaterialsName i.name then (
                        append AllSceneMaterials i
                    ) else (
                        i.name = i.name + "-" + (timeStamp() as string)
                        append AllSceneMaterials i
                    )
                )
            )
        )
        return AllSceneMaterials
    )

    function ConvertGamma acolor gamma = 
    (
        r = (acolor.r / 255.0) ^ gamma * 255
        g = (acolor.g / 255.0) ^ gamma * 255
        b = (acolor.b / 255.0) ^ gamma * 255
        
        return (color r g b)
    )

    function fbxtext2Hex s =
    (
        local ch = "abcdefghijklmnopqrstuvwxyz123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        local hex = ""
        for i=1 to s.count do
            if (findString ch s[i] == undefined) then
                hex += "FBXASC0"+(bit.charAsInt s[i]) as string
            else
                hex += s[i]	
        return hex
    )

    function rescaleObjects = 
    (
        scaleFac = 1
        case units.SystemType of (
            #Inches:scaleFac = 0.0253999998
            #Feet:scaleFac = 0.304799998
            #Miles:scaleFac = 1609.3439893783
            #Millimeters:scaleFac = 0.001
            #Centimeters:scaleFac = 0.01
            #Meters:scaleFac = 1
            #Kilometers:scaleFac = 1000
        )

        if units.SystemType != #Meters do (
            units.SystemType = #Meters
            RescaleWorldUnits scaleFac
        )
    )

    function CleanMeditSlot =
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

    --整理所有材质
    function CleanUpMaterials = 
    (        
        for i in getClassInstances VRayOverrideMtl do (
            if i.baseMtl != undefined do (
                _t = i.baseMtl
                replaceinstances i _t
            )
        )
        for i in getClassInstances VRayBlendMtl do (
            _t = i.baseMtl
            replaceinstances i _t
        )
        
        for i in getClassInstances VrayMtlWrapper do (
            _t = i.baseMtl
            replaceinstances i _t
        )

        for i in getClassInstances VRayBitmap do (
            print "3.>>>>>"
            
            for f in refs.dependents i do (
                print (classof f)
            )
        )



        /*
        for mat in getClassInstances VRayMtl do (
            for p in getPropNames VRayMtl do (
                if (findString (p as string) "texmap_") != undefined do (
                    att = getProperty mat (p as string)
                    if superClassOf att == textureMap do (
                        tex = FixTexture att
                        setProperty mat p tex
                    )  
                )
            )
        )
        */

    )
    
    function ShapeToPoly =
    (
        for i in Shapes do (
            if i.render_renderable == true do (
                convertToPoly i
            )
        )
    )
    
    function CleanUpUnShpae =
    (
        allshape = #()
        for x in shapes do
        (
            tmp = refs.dependents x
            for i = 1 to tmp.count do
            (
                if (superclassof tmp[i]) == GeometryClass then
                (
                    a = findItem allshp x
                    if a != 0 then append allshp a
                )
            )
        )
        delete allshp
    )
    
    function DeleteEmptyPoly =
    (
        sel = #()
        for i in Geometry do 
        (
            try(if getNumFaces i == 0 then append sel i)catch()
        )
        delete sel
    )
    
    function ResetGroupPivot =
    (
        groups = for i in objects where isGroupHead i collect i
        for i in groups do (
            -- CenterPivot i
            ResetPivot i
        )
    )
    
    function ClearUserProp =
    (
        for i in objects do (
            setUserPropBuffer i ""
        )
    )
    
    function setRegistryKey key subkey val =
    (
        registry.openKey HKEY_CURRENT_USER key accessRights:#all key:&key1
        registry.createKey HKEY_CURRENT_USER key accessRights:#all newKeyCreated:&newKeyCreated key:&key1
        registry.setValue key1 subkey #REG_SZ val
    )

    function CleanupTexture tex =
    (
        type = classof tex
        
        case type of (
            Mask:(
                -- print tex
                map = tex.map
                tex.map = CleanupTexture map
                tex.mask = CleanupTexture tex.mask
            )
            Bitmaptexture:(
                -- print tex.filename
                filename = tex.filename

                if filename == undefined do (
                    tex = undefined
                )

                tex_name = tex.name
                tex_mode_on = tex.apply
                tex_clip_width = tex.clipw
                tex_clip_height = tex.cliph

                filepath = getFilenamePath tex.HDRIMapName
                filename = getFilenameFile tex.HDRIMapName
                filetype = getFilenameType tex.HDRIMapName
                
                bm = undefined

                if tex_mode_on or ( tex_clip_width < 1 or tex_clip_height < 1 ) then (
                    newfile = filepath + filename + "_crop" + filetype
                    nb = renderMap tex size:[512, 512] filename:newfile
                    
                    try(save nb)catch()
                    close nb
                    
                    bm = Bitmaptexture filename:newfile
                    bm.name = tex_name
                    tex = bm
                )
            )
            VRayBitmap:(
                -- print tex.HDRIMapName
                tex_name = tex.name
                tex_mode_on = tex.cropplace_on
                tex_mode_type = tex.cropplace_mode
                tex_clip_width = tex.cropplace_width
                tex_clip_height = tex.cropplace_height
                
                filepath = getFilenamePath tex.HDRIMapName
                filename = getFilenameFile tex.HDRIMapName
                filetype = getFilenameType tex.HDRIMapName
                
                bm = undefined
                
                if tex.HDRIMapName == undefined then (				
                    tex = undefined
                )
                
                if tex_mode_on or (tex_clip_width < 1 or tex_clip_height < 1) then (
                    newfile = filepath + filename + "_crop" + filetype
                    nb = renderMap tex size:[512, 512] filename:newfile
                    
                    try(save nb)catch()
                    close nb
                    
                    bm = Bitmaptexture filename:newfile
                    bm.name = tex_name
                    
                ) else (	
                    bm = Bitmaptexture filename:tex.HDRIMapName
                    bm.name = tex_name
                )			
                
                replaceInstances tex bm
                tex = bm
            )
            default: (
                tex = undefined
            )
        )
        return tex
    )
    /*
    *    UI
    */
    try(DestroyDialog ::M2B) catch()

    rollout M2B "Export2Blender(20220222)-RedHalo Studio(发霉的红地蛋)"
    (
        local RedHalo_Exp_SmoothGroup = true
        local RedHalo_Exp_Animation = true
        local RedHalo_Exp_Cameras = false
        local RedHalo_Exp_Lights = false
        local xmlname = "RH_M2B.xml"
        local fbxname = "RH_M2B.fbx"
        local export_path = sysInfo.tempdir
        local export_mode = 0
        local export_proxy = true

        --XML NODE VARS
        global ProxyListElement

        global Material_List = #()

        global CR_Diffuse = #(#colordiffuse, #texmapDiffuse)
        global VR_Diffuse = #("Diffuse", "texmap_diffuse")
        global DiffuseAttrib = #("Color", "Texmap")

        global CR_Metallic = #(#reflection_metalness, #texmap_metalness)
        global VR_Metallic = #(#reflection_metalness, #texmap_metalness)
        global MetallicAttrib = #("Amount", "Texmap")

        global CR_Reflect = #(#colorreflect, #texmapReflect)
        global VR_Reflect = #("Reflection",  "texmap_reflection")
        global ReflectAttrib = #("Amount", "Texmap")

        global CR_Roughness = #(#reflectGlossiness, #texmapReflectGlossiness)
        global VR_Roughness = #("reflection_Glossiness", "texmap_reflectionGlossiness")
        global RoughnessAttrib = #("Amount", "Texmap")

        global CR_Anisotropy = #(#anisotropy, #texmapOnAnisotropy)
        global VR_Anisotropy = #("anisotropy", "texmap_anisotropy")
        global AnisotropyAttrib = #("Amount", "Texmap")

        global CR_AnisotropyRotation = #(#anisotropyRotation, #texmapOnAnisotropyRotation)
        global VR_AnisotropyRotation = #("anisotropy_rotation",  "texmap_anisotropy_rotation")
        global AnisotropyRotationAttrib = #("Amount", "Texmap")

        global CR_Sheen = #()
        global VR_Sheen = #("sheen_color", "texmap_sheen")
        global SheenAttrib = #("Amount", "Texmap")

        global CR_Coat = #()
        global VR_Coat = #("coat_amount", "texmap_coat_color")
        global CoatAttrib = #("Amount", "Texmap")

        global CR_CoatRoughness = #()
        global VR_CoatRoughness = #("coat_glossiness", "texmap_coat_glossiness")
        global CoatRoughnessAttrib = #("Amount", "Texmap")

        global CR_IOR = #(#fresnelIor, #texmapfresnelior)
        global VR_IOR = #( "reflection_ior", "texmap_reflectionior") --"refraction_ior", "texmap_refractionIOR", "texmap_reflectionior", "reflection_lockior")
        global IORAttrib = #("Amount", "Texmap")

        global CR_Refract = #(#levelrefract, #texmapRefract)
        global VR_Refract = #("Refraction", "texmap_refraction")
        global RefractAttrib = #("Amount", "Texmap")

        global CR_RefractRoughness = #(#refractGlossiness, #texmapRefractGlossiness)
        global VR_RefractRoughness = #("refraction_glossiness", "texmap_refractionGlossiness")
        global RefractRoughnessAttrib = #("Amount", "Texmap")

        global CR_Emission = #(#COLORSELFILLUM, #texmapSelfIllum)
        global VR_Emission = #("selfIllumination", "texmap_self_illumination")
        global EmissionAttrib = #("Color", "Texmap")

        global CR_EmissionStrength = #(#LEVELSELFILLUM)
        global VR_EmissionStrength = #("selfIllumination_multiplier", "texmap_self_illumination_multiplier")
        global EmissionStrengthAttrib = #("Amount", "Texmap")

        global CR_Opacity = #(#texmapOpacity)
        global VR_Opacity = #(#texmap_opacity_multiplier, #texmap_opacity)
        global OpacityAttrib = #("Amount", "Texmap")

        global CR_Bump = #(#mapamountBump, #texmapBump)
        global VR_Bump = #("texmap_bump_multiplier", "texmap_bump")
        global BumpAttrib = #("Amount", "Texmap")

        global CR_Translucent = #(#texmaptranslucency)
        global VR_Translucent = #("texmap_translucent")
        global TranslucentAttrib = #("Texmap")

        global CR_Displacement = #(#displacementMaximum, #texmapdisplace)
        global VR_Displacement = #("texmap_displacement_multiplier", "texmap_displacement")
        global DisplacementAttrib = #("Amount", "Texmap")

        global BitmapProps = #("clipu", "clipv", "clipw", "cliph", "alphasource", "filename")
        global CoordsProps = #("U_Tile", "V_Tile", "U_Tiling", "V_Tiling", "U_Offset", "V_Offset", "W_Angle", "V_Angle", "U_Angle")

        global CheckerProps = #("color1", "color2", "map1", "map2", "map1Enabled", "map2Enabled")

        -- Node Array ---
        global NodeNames = #("Diffuse", "Metallic", "Reflection", "Roughness", "Anisotropic", "AnisotropicRotation", "Sheen", "Coat", "CoatRoughness", "IOR", "Refraction", "RefractRoughness", "Emission", "EmissionStrength", "Opacity", "Bump", "Translucent", "Displacement")
        global VR_PropsArray = #(VR_Diffuse, VR_Metallic, VR_Reflect, VR_Roughness, VR_Anisotropy, VR_AnisotropyRotation, VR_Sheen, VR_Coat, VR_CoatRoughness, VR_IOR, VR_Refract, VR_RefractRoughness, VR_Emission, VR_EmissionStrength, VR_Opacity, VR_Bump, VR_Translucent, VR_Displacement)
        global CR_PropsArray = #(CR_Diffuse, CR_Metallic, CR_Reflect, CR_Roughness, CR_Anisotropy, CR_AnisotropyRotation, CR_Sheen, CR_Coat, CR_CoatRoughness, CR_IOR, CR_Refract, CR_RefractRoughness, CR_Emission, CR_EmissionStrength, CR_Opacity, CR_Bump, CR_Translucent, CR_Displacement)

        -- VR_NodeProps = #(DiffuseProps)
        global NodeAttribNames = #(DiffuseAttrib, MetallicAttrib, ReflectAttrib, RoughnessAttrib, AnisotropyAttrib, AnisotropyRotationAttrib, SheenAttrib, CoatAttrib, CoatRoughnessAttrib, IORAttrib, RefractAttrib, RefractRoughnessAttrib, EmissionAttrib, EmissionStrengthAttrib, OpacityAttrib, BumpAttrib, TranslucentAttrib, DisplacementAttrib)

        groupBox gb1 "导出选项" width:300 height:65 pos:[5,5]
        checkbutton cb_export_all "所有物体" checked:true height:40 width:145 pos:[10,20] tooltip:"导出场景中所有物体"
        checkbutton cb_export_sel "选择物体" checked:false height:40 width:145 pos:[155,20] tooltip:"导出场景中选择的物体"

        groupBox gb2 "模型选项" width:300 height:60 pos:[5, 75] enabled:false
        checkbutton cb_m_fbx_smoothGroup "Smoothing Groups" checked:true height:20 width:170 pos:[15, 90] enabled:false
        -- checkbutton cb_m_fbx_camera "Camera" checked:true height:20 width:170 pos:[15, 120] enabled:false
        -- checkbutton cb_m_fbx_Lights "Lights" checked:true height:20 width:170 pos:[15, 140] enabled:false
        checkbutton cb_m_fbx_Animation "Animation" checked:true height:20 width:170 pos:[15, 110] --enabled:false
        -- checkbutton cb_m_fbx_ConvertUnit "Convert Unit" checked:true height:20 width:170 pos:[15, 180] enabled:false
        
        groupbox gb3 "导出文件位置" width:300 height:60 pos:[5, 140]
        -- edittext et_folder "" width:270 pos:[5, 182] readonly:true enabled:false
        -- button btn_folder "..." width:20 height:20 pos:[275, 180]
        button btn_folder "" width:290 height:30 pos:[10, 160] border:false tooltip:"点击选择导出目录" enabled:false

        button btn_export "导出" width:85 height:120 pos:[310,10]
        button btn_about "?" width:85 height:30 pos:[310, 130]  tooltip:"帮助说明"

        ---------Function BEGIN------------
        fn ExportAnimate obj start end = (
            transform_array = ""
            for t = start to end do (
                at time t (
                    tmp = "@" + obj.transform as string
                    transform_array += tmp
                )
            )
            return transform_array
        )

        fn FixDuplicatName array obj =(
            if appendIfUnique array obj.name == false then (
                newname = obj.name + "_" + timeStamp() as string
                obj.name = newname
                FixDuplicatName array obj
            )
        )

        fn setPivot obj Pivot:2 = (
            -- Pivot
            -- 0: 上中  1：中间  2：下中
            max = obj.max
            min = obj.min
            center = max - min

            case Pivot of (
                0: obj.pivot = [center.x, center.y, max.z]
                1: obj.pivot = [center.x, center.y, center.z]
                2: obj.pivot = [center.x, center.y, min.z]
                default: obj.pivot = [center.x, center.y, center.z]
            )
        )

        function DuplicateObjectNam = 
        (
            FixObjNames = #() 
            for i in objects do (
                FixDuplicatName FixObjNames i
            )
        )

        function SetColor parentNode prop_name clr = 
        (
            texture_type = classof parentNode
            if texture_type == RGB_Multiply or texture_type == Checker or texture_type == Falloff or texture_type == Noise do (
                if prop_name == #map1 do setProperty parentNode #Color1 clr
                if prop_name == #map2 do setProperty parentNode #Color2 clr
            )

            if texture_type == Color_Correction do setProperty parentNode #color clr
            
            if texture_type == BlendedBoxMap do setProperty parentNode #tex[1] clr

            if texture_type == Mix do (
                if prop_name == #map1 do setProperty parentNode #Color1 clr
                if prop_name == #map2 do setProperty parentNode #Color2 clr                                
                if prop_name == #Mask do setProperty parentNode #mixAmount (clr.v / 255.0)
            )

            if texture_type == Bricks do (
                if prop_name == #Bricks_Map do setProperty parentNode #Brick_color clr
                if prop_name == #Mortar_Map do setProperty parentNode #Mortar_color clr
            )

            if texture_type == VRayDirt do (
                if prop_name == #texmap_unoccluded_color do setProperty parentNode #unoccluded_color clr
                if prop_name == #texmap_occluded_color do setProperty parentNode #occluded_color clr
            )

            if texture_type == VRayDistanceTex do (
                if prop_name == #texmap_far do setProperty parentNode #far_color clr
                if prop_name == #texmap_near do setProperty parentNode #near_color clr
                if prop_name == #texmap_inside do setProperty parentNode #inside_color clr
                if prop_name == #texmap_outside do setProperty parentNode #outside_color clr
            )

            if texture_type == VRayUserColor do (
                if prop_name == #default_texmap do setProperty parentNode #default_color clr
            )

            if texture_type == ColorMap do (
                if prop_name == #map do setProperty parenetNode #SOLIDCOLOR clr
            )
        )

        function FixTexture texture =
        (
            case classof texture of (
                Mix:(
                    texture.map1 = FixTexture texture.map1
                    texture.map2 = FixTexture texture.map2
                    return texture
                )
                Checker:(
                    texture.map1 = FixTexture texture.map1
                    texture.map2 = FixTexture texture.map2
                    return texture
                )
                ColorCorrection:(
                    texture.map = FixTexture texture.map
                    return texture
                )
                CompositeTexturemap:(
                    return FixTexture texture.maplist[1]
                )
                Bitmaptexture:(
                    oldfile = texture.filename
                    filepath = getFilenamePath oldfile
                    filename = getFilenameFile oldfile
                    filetype = getFilenameType oldfile

                    img_crop = texture.apply
                    img_w = texture.clipw
                    img_h = texture.cliph

                    if img_crop and (img_w < 1 or img_h <1) do (
                        newfile = filepath + filename + "_crop" + filetype
                        bm = renderMap texture size:[512, 512] filename:newfile
                        try(save bm)catch()
                        close bm

                        texture.filename = newfile
                        texture.apply = false
                        texture.clipw = 1
                        texture.cliph = 1
                    )

                    return texture
                )
                Falloff:(
                    texture.map1 = FixTexture texture.map1
                    texture.map2 = FixTexture texture.map2
                    return texture
                )
                Gradient:(
                    texture.map1 = FixTexture texture.map1
                    texture.map2 = FixTexture texture.map2
                    texture.map3 = FixTexture texture.map3
                    return texture
                )
                RGB_Multiply:(
                    texture.map1 = FixTexture texture.map1
                    texture.map2 = FixTexture texture.map2
                    return texture
                )
                Tiles:(
                    texture.Mortar_Map = FixTexture texture.Mortar_Map
                    texture.Bricks_Map = FixTexture texture.Bricks_Map
                    return texture
                )
                Cellular:(
                    return FixTexture texture.cellMap
                )
                VRayBump2Normal:(
                    texture.bump_map = FixTexture texture.bump_map
                    return texture
                )
                VRayColor2Bump:(
                    texture.map = FixTexture texture.map
                    return texture
                )
                VRayCompTex:(
                    return FixTexture texture.sourcea
                )
                VRayDirt:(
                    texture.texmap_occluded_color = FixTexture texture.texmap_occluded_color
                    texture.texmap_unoccluded_color = FixTexture texture.texmap_unoccluded_color
                    texture.texmap_radius = FixTexture texture.texmap_radius
                    
                    return texture
                )
                VRayMultiSubTex:(
                    return FixTexture texture.default_texmap
                )
                VRayTriplanarTex:(
                    return FixTexture texture.texture
                )
                VRayNormalMap:(
                    texture.normal_map = FixTexture texture.normal_map
                    texture.bump_map = FixTexture texture.bump_map
                    return texture
                )
                VRayBitmap:(
                    print "1.>>>>>"
                    if texture.HDRIMapname != undefined then (
                        return texture
                    )else(
                        return undefined
                    )
                )
                VRayEdgesTex:(
                    return undefined
                )
                default:(
                    return undefined
                )
            )
        )

        fn FindTexture texture = (
            tmp = refs.dependents texture
            for x = 1 to tmp.count do (		
                supetClass = superclassof tmp[x]
                if supetClass == textureMap or supetClass == material do (
                    for prop_name in (getPropNames (classof tmp[x])) do (
                        att = getProperty tmp[x] prop_name
                        if att == texture do (
                            setProperty tmp[x] prop_name undefined

                            clr = texture.color                             
                            setColor tmp[x] prop_name clr
                        )
                    )      
                )
            )
        )

        /*------------------------------------------------------
        --------------------- GLOBAL VARS ----------------------
        ------------------------------------------------------*/

        ------- Bitmap Node BEGIN  ------------
        /*
        *ParentNode 父级节点
        *Bitmaptexture 子属性
        */
        fn CreateBitmapNode xmlDoc ParentNode Bitmaptexture = (

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
        fn CreateElement xmlDoc ParentNode Texture = (
            /*
            ### ParentNode
            */
            TextureType = ClassOf Texture
            case TextureType of (
                Bitmaptexture:(
                    CreateBitmapNode xmlDoc ParentNode Texture
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
                    CreateElement xmlDoc MortarNode tex_Mortar

                    tex_Tile = getProperty Texture "Bricks_Map"
                    CreateElement xmlDoc TileNode tex_Tile

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
                    CreateElement xmlDoc CheckerMap1Node Map1

                    CheckerMap2Node = xmlDoc.CreateElement "Checker_Map2"
                    CheckerNode.appendChild CheckerMap2Node
                    Map2 = getProperty Texture "map2"
                    CreateElement xmlDoc CheckerMap2Node Map2
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
                    CreateElement xmlDoc Map1Node Map1

                    Map2Node = xmlDoc.CreateElement "Map2"
                    MixNode.appendChild Map2Node
                    Map2 = getProperty Texture "map2"
                    CreateElement xmlDoc Map2Node Map2

                    MaskNode = xmlDoc.CreateElement "Mask"
                    MixNode.appendChild MaskNode
                    MaskMap = getProperty Texture "Mask"
                    CreateElement xmlDoc MaskNode MaskMap

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
                    CreateElement xmlDoc map1Node map1

                    map2Node = xmlDoc.CreateElement "map2"
                    FalloffNode.appendChild map2Node
                    map2 = getProperty Texture "map2"
                    CreateElement xmlDoc map2Node map2

                )
                Color_Correction:(

                    CCNode = xmlDoc.CreateElement "ColorCorrection"
                    ParentNode.appendChild CCNode

                    CCParams = #("color", "map", "rewireMode", "HUESHIFT", "saturation", "LIGHTNESSMODE", "BRIGHTNESS", "contrast", "GAMMARGB")
                    -- CCParams = getPropNames Color_Correction
                    for i in CCParams do (
                        atts = getProperty Texture i
                        CCNode.setAttribute i (atts as string)
                    )

                    CCMap = xmlDoc.CreateElement "Map"
                    CCNode.appendChild CCMap
                    map = getProperty Texture "map"
                    CreateElement xmlDoc CCMap map
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
                    CreateElement xmlDoc Map1Node Map1
                    
                    Map2Node = xmlDoc.CreateElement "Map2"
                    RGBMultNode.appendChild Map2Node
                    Map2 = getProperty Texture "map2"
                    CreateElement xmlDoc Map2Node Map2
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
                    CreateElement xmlDoc OccludedNode OccludedMap

                    AONode.appendChild UnoccludedNode
                    UnoccludedMap = getProperty texture "texmap_unoccluded_color"
                    CreateElement xmlDoc UnoccludedNode UnoccludedMap

                    AONode.appendChild RadiusNode
                    RadiusMap = getProperty texture "texmap_radius"
                    CreateElement xmlDoc RadiusNode RadiusMap

                )
                VrayBump2Normal:(
                    params = #("bump_map", "bump_map_mult", "mode", "map_channel")

                    NormalNode = xmlDoc.CreateElement "Bump"
                    ParentNode.appendChild NormalNode

                    for p in params do (
                        att = getProperty texture p
                        NormalNode.setAttribute p (att as string)
                    )

                    MapNode = xmlDoc.CreateElement "NormalMap"
                    NormalNode.appendChild MapNode
                    Map = getProperty  texture "bump_map"
                    CreateElement xmlDoc MapNode map
                )
                Vertex_Color:(
                    VCNode = xmlDoc.CreateElement "VertexColor"
                    ParentNode.appendChild VCNode
                )
                VRayNormalMap:(
                    params = #("normal_map", "normal_map_on", "normal_map_multiplier", "bump_map", "bump_map_on", "bump_map_multiplier", "map_channel", "flip_red", "flip_green", "swap_red_and_green", "map_rotation", "apply_gamma", "blue2Z_mapping_method")

                    BumpNode = xmlDoc.CreateElement "Bump"
                    ParentNode.appendChild BumpNode
                    
                    for p in params do (
                        att = getProperty texture p
                        BumpNode.setAttribute p (att as string)
                    )

                    MapNormalNode = xmlDoc.CreateElement "NormalMap"
                    BumpNode.appendChild MapNormalNode
                    map1 = getProperty texture "normal_map"
                    CreateElement xmlDoc MapNormalNode map1

                    MapBumpNode = xmlDoc.CreateElement "HeightMap"
                    BumpNode.appendChild MapBumpNode
                    map2 = getProperty texture "bump_map"
                    CreateElement xmlDoc MapBumpNode map2

                )
                VRayColor2Bump:(
                    params = #(#map, #height, #bump_delta_scale)

                    BumpNode = xmlDoc.CreateElement "Bump"
                    ParentNode.appendChild BumpNode

                    for p in params do (
                        att = getProperty texture p
                        BumpNode.setAttribute p (att as string)
                    )

                    MapNormalNode = xmlDoc.CreateElement "NormalMap"
                    BumpNode.appendChild MapNormalNode

                    MapBumpNode = xmlDoc.CreateElement "HeightMap"
                    BumpNode.appendChild MapBumpNode
                    MapBump = getProperty texture "map"
                    CreateElement xmlDoc MapBumpNode MapBump
                )
                VRayBitmap:(
                    print "2.>>>>>>"
                    if texture.HDRIMapName != undefined then (
                        bm = Bitmaptexture filename:texture.HDRIMapName
                        CreateBitmapNode xmlDoc ParentNode bm
                    ) else (
                        bm = undefined
                    )
                    
                )
            )
        )

        fn ExportSetting xmlDoc ParentNode = (

            FileElement = xmlDoc.CreateElement "File"
            ParentNode.appendChild FileElement
            _filename = getFilenameFile maxfilename
            if _filename == "" do _filename = "M2B_Untitled"
            FileElement.innerText = maxfilename

            RenderElement = xmlDoc.CreateElement "Renderer"
            ParentNode.appendChild RenderElement
            RenderElement.innerText = (filterString (renderers.current as string) ":")[1]

            GammaElement = xmlDoc.CreateElement "Gamma"
            ParentNode.appendChild GammaElement
            GammaElement.innerText = FileInGamma as string

            WidthElement = xmlDoc.CreateElement "Width"
            ParentNode.appendChild WidthElement
            WidthElement.innerText = renderWidth as string

            HeightElement = xmlDoc.CreateElement "Height"
            ParentNode.appendChild HeightElement
            HeightElement.innerText = renderHeight as string

            UnitElement = xmlDoc.CreateElement "Units"
            ParentNode.appendChild UnitElement
            UnitElement.innerText = units.SystemType as string
        )

        fn ExportLight xmlDoc ParentNode = (
            
            for i in Lights do (
                -- Lights List
                L_Color = "(color 255 255 255)"
                L_Multiplier = "1"
                L_Type = "AREA"
                L_Length = 0.1
                L_Width = 0.1
                L_IES = "undefined"
                L_Hotspot = "0"
                L_Falloff = "45"
                L_Invisible = false
                L_Shadow = true
                L_Diffuse = true
                L_Specular = true
                L_Reflection = true
                L_Portal = false
                
                LightType = classof i
                if LightType != TargetObject do (
                    case LightType of (
                        Target_Light:(
                            L_Color = i.rgbFilter
                            L_Multiplier = i.intensity / 1000 

                            if i.Distribution == 3 do (
                                L_Type = "POINT"
                                L_IES = i.webfile
                            )
                            if i.Distribution == 1 do (
                                L_Type = "SPOT"
                                L_IES = "undefined"
                                L_Hotspot = i.Hotspot
                                L_Falloff = i.falloff
                            )
                            if i.Distribution == 2 or i.Distribution == 0 do (
                                L_Type = "POINT"
                                L_IES = "undefined"
                            )
                        )
                        Free_Light:(
                            L_Color = i.rgbFilter
                            L_Multiplier = i.intensity / 1000 

                            if i.Distribution == 3 do (
                                L_Type = "POINT"
                                L_IES = i.webfile
                            )
                            if i.Distribution == 1 do (
                                L_Type = "SPOT"
                                L_IES = "undefined"
                                L_Hotspot = i.Hotspot
                                L_Falloff = i.falloff
                            )
                            if i.Distribution == 2 or i.Distribution == 0 do (
                                L_Type = "POINT"
                                L_IES = "undefined"
                            )
                        )
                        targetSpot:(
                            L_Color = i.rgb
                            L_Multiplier = i.multiplier 
                            L_Type = "SPOT"
                            L_Hotspot = i.Hotspot
                            L_Falloff = i.falloff
                        )
                        freeSpot:(
                            L_Color = i.rgb
                            L_Multiplier = i.multiplier                     
                            L_Type = "SPOT"
                            L_Hotspot = i.Hotspot
                            L_Falloff = i.falloff
                        )
                        TargetDirectionallight:(
                            L_Color = i.rgb
                            L_Multiplier = i.multiplier 
                            L_Type = "SUN"
                        )
                        Directionallight:(
                            L_Color = i.rgb
                            L_Multiplier = i.multiplier 
                            L_Type = "SUN"
                        )
                        Omnilight:(
                            L_Color = i.rgb
                            L_Multiplier = i.multiplier 
                            L_Type = "POINT"
                        )
                        VRayLight:(
                            L_Color = i.color
                            L_Multiplier = i.multiplier

                            case i.type of (
                                0: L_type = "AREA"
                                2: L_Type = "POINT"
                                4: L_Type = "DISK"
                            )

                            L_Length = i.sizeLength
                            L_Width = i.sizeWidth
                            L_Invisible = i.invisible
                            L_Shadow = i.castshadows
                            L_Diffuse = i.affect_diffuse
                            L_Specular = i.affect_specular
                            L_Reflection = i.affect_reflections
                            L_Portal = i.SkylightPortal
                        )
                        VRayIES: (
                            L_Color = i.color
                            L_Multiplier = i.power
                            L_Type = "POINT"
                            L_Length = 0.1
                            L_Width = 0.1
                            L_IES = i.ies_file
                            L_Invisible = ""
                            L_Diffuse = i.affect_diffuse
                            L_Shadow = i.cast_shadows
                            L_Specular = i.affect_specular
                            L_Reflections = true
                            L_Portal = false                     
                        )
                        VRaySun:(
                            L_Color = i.filter_Color
                            L_Multiplier = i.intensity_multiplier
                            L_type = "SUN"
                            L_Length = i.size_multiplier
                            L_Width = "0.1"
                            L_Invisible = i.invisible
                            L_Shadow = "true"
                            L_Diffuse = i.affect_diffuse
                            L_Specular = i.affect_specular
                            L_Reflection = "false"
                            L_Portal = "false"
                        )
                        CoronaLight:()
                        CoronaSun:()
                    )

                    LightsList = xmlDoc.CreateElement "Light"
                    ParentNode.appendChild LightsList

                    LightsList.setAttribute "name" i.name
                    LightsList.setAttribute "matrix" (i.transform as string)
                    LightsList.setAttribute "color" (L_Color as string)
                    LightsList.setAttribute "multiplier" (L_Multiplier as string)
                    LightsList.setAttribute "type" L_Type
                    LightsList.setAttribute "length" (L_Length as string)
                    LightsList.setAttribute "width" (L_Width as string)
                    LightsList.setAttribute "ies" L_IES
                    LightsList.setAttribute "hotspot" (L_Hotspot as string)
                    LightsList.setAttribute "falloff" (L_Falloff as string)
                    LightsList.setAttribute "caseshadows" (L_Shadow as string)
                    LightsList.setAttribute "invisible" (L_Invisible as string)
                    LightsList.setAttribute "affectdiffuse" (L_Diffuse as string)
                    LightsList.setAttribute "affectspecular" (L_Specular as string)
                    LightsList.setAttribute "affectreflections" (L_Reflections as string)
                    LightsList.setAttribute "portal" (L_Portal as string)
                )
            )
                    
        )

        fn ExportCamera xmlDoc ParentNode = (
            -- Camera List
            for i in Cameras do (
                if classof i != TargetObject do (
                    name = i.name
                    fov = i.fov as string
                    matrix = i.transform
                    nearclip = 1
                    farclip = 1000
                    clip = false
                    tilt = "0,0"
                    shift = "0,0"                    
                    animate_data_transform = ""
                    animate_date_fov = ""

                    case classof i of (
                        Targetcamera:(
                            nearclip = i.nearclip
                            farclip = i.farclip
                            clip = i.clipManually
                        )
                        Freecamera:(
                            nearclip = i.nearclip
                            farclip = i.farclip
                            clip = i.clipManually
                        )
                        Physical:(
                            nearclip = i.near_clip
                            farclip = i.far_clip
                            clip = i.clip_on
                            tilt = (i.horizontal_tilt_correction as string) + "," + (i.vertical_tilt_correction as string)
                            shift = (i.horizontal_shift as string) + "," + (i.vertical_shift as string)
                        )
                        VRayPhysicalCamera:(
                            nearclip = i.clip_near
                            farclip = i.clip_far
                            clip = i.clip_on
                            tilt_x = i.lens_tilt 
                            tilt_y = i.lens_horTilt
                            shift_x = i.horizontal_shift
                            shift_y = i.vertical_shift
                            tilt = (tilt_x as string) + "," + (tilt_y as string)
                            shift = (shift_x as string) + "," + (shift_y as string)
                        )
                        CoronaCam:(
                            nearclip = i.clippingNear
                            farclip = i.clippingFar
                            clip = i.enableclipping
                        )
                    )

                    cameraList = xmlDoc.createElement "Camera"
                    cameraList.setAttribute "name" name
                    cameraList.setAttribute "fov" fov
                    cameraList.setAttribute "clip" (clip as string)
                    cameraList.setAttribute "near" (nearclip as string)
                    cameraList.setAttribute "far" (farclip as string)
                    cameraList.setAttribute "matrix" (matrix as string)
                    cameraList.setAttribute "tilt" tilt
                    cameraList.setAttribute "shift" shift
                    cameraList.setAttribute "animate_data_transform" "0"
                    cameraList.setAttribute "animate_data_fov" ""
                    ParentNode.appendChild cameraList

                    Transform_data_xml = xmlDoc.CreateElement "Transform"
                    CameraList.appendChild transform_data_xml
                    
                    for t = animationRange.start to animationRange.end do (
                        frame_xml = xmlDoc.CreateElement "frame"
                        Transform_data_xml.appendChild frame_xml

                        frame_xml.setAttribute "frame" (t as string)
                        frame_xml.setAttribute "transform" (i.transform as string)
                    )
                )
            )
        )

        fn ExportEnvironment xmlDoc ParentNode = (

            env_color = (color 255 255 255)
            env_texmap = undefined
            env_multiplier = 1

            DemoLights = for i in Lights where classof i == Skylight collect i

            for i in Lights do (
                if classof i == VRayLight do (
                    if i.type == 1 do (
                        append DemoLights i
                    )
                )
            )

            if DemoLights.count > 0 then (
                -- VRay Demo
                ---- color
                ---- texmap
                ---- multiplier
                ---- texmap_locktodome

                -- Skylight
                ---- color
                ---- skymode
                ---- multiplier
                ---- sky_color_map

                -- 仅导出第一个
                
                DemoLight = DemoLights[1]
                LightType = classof DemoLight
                case LightType of (
                    VRayLight:(
                        env_color = DemoLight.color
                        env_texmap = DemoLight.texmap
                        env_multiplier = DemoLight.multiplier
                    )
                    Skylight:(
                        env_color = DemoLight.color
                        env_texmap = DemoLight.sky_color_map
                        env_multiplier = DemoLight.multiplier
                    )
                )
            )else(
                env_color = backgroundColor
                env_multiplier = 1
                env_texmap = environmentMap
            )
            
            Env_Color_Element = xmlDoc.CreateElement "Color"
            ParentNode.appendChild Env_Color_Element
            Env_Color_Element.InnerText = env_color as string

            Env_Multiplier_Element = xmlDoc.CreateElement "Multiplier"
            ParentNode.appendChild Env_Multiplier_Element
            Env_Multiplier_Element.innerText = env_multiplier as string

            Env_Map_Element = xmlDoc.CreateElement "Texmap"
            ParentNode.appendChild Env_Map_Element
            Env_Map_Element.setAttribute "Texmap" (env_texmap as string)

            CreateElement xmlDoc Env_Map_Element env_texmap
        )

        fn ExportProxy xmlDoc ParentNode = (
            -- VRayProxy
            for i in getClassInstances VRayProxy do (            
                proxyitem = xmlDoc.CreateElement "ProxyItem"
                ParentNode.appendChild proxyitem
                
                proxy_filename = i.filename
                proxy_scale = i.proxy_scale
                proxy_name = getFilenameFile proxy_filename
                i.display = 0
                            
                proxys = for j in refs.dependents i where classof j == VRayProxy collect j
                newname = "RHPROXYSOURCE_" + timeStamp() as string + "_" + proxy_name
                proxyitem.setAttribute "name" newname
                proxyitem.setAttribute "count" (proxys.count as string)
                proxyitem.setAttribute "filename" proxy_filename
                proxyitem.setAttribute "type" "VRayProxy"
                
                proxy_source = copy proxys[1]
                proxy_source.display = 4
                proxy_source.name = newname
                proxy_source.transform = matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]
                ResetXForm proxy_source
                convertToPoly proxy_source
                
                for p in proxys do (
                    proxy_list = xmlDoc.CreateElement "ProxyList"
                    ProxyItem.appendChild proxy_list

                    proxy_list.setAttribute "name" p.name
                    proxy_list.setAttribute "matrix" (p.transform as string)
                )
                delete proxys
            )

        )
        /*-------------------------------------
        ---------- FUNCTION END ---------------
        -------------------------------------*/

        on M2B open do (
            set_export_path = ""
            registry.openKey HKEY_CURRENT_USER "SOFTWARE\\REDHALO" accessRights:#all key:&key1
            if key1 != undefined then
                registry.queryValue key1 "Export" type:#REG_SZ value:&set_export_path expand:false
            
            btn_folder.text = set_export_path

            AllMats = #()
            for cls in material.classes do (
                if cls != Multimaterial do (
                    for m in getClassInstances cls do (
                        append AllMats m
                    )
                )
            )
        )

        on cb_export_all changed state do (
            cb_export_sel.checked = not state
            if state then (
                export_mode = 0
            )else(
                export_mode = 1
            )
        )

        on cb_export_sel changed state do (
            cb_export_all.checked = not state
            
            if state then (
                export_mode = 1
            )else(
                export_mode = 0
            )
        )

        on cb_m_fbx_Animation changed state do (
            RedHalo_Exp_Animation = state
        )

        on btn_about pressed do (
            messageBox "此版本编译于2022-02-11\n此版本限制：仅支持Vray英文版，不支持汉化版本\n其它材质不会导出"
        )

        on btn_folder pressed do (
            folder = getSavepath()
            if folder != undefined do (
                et_folder.text = folder

                -- 写入注册表        
                setRegistryKey "SOFTWARE\\REDHALO" "Export" folder
            )
        )

        on btn_export pressed do (           
            --Load the xml assembly
            dotNet.loadAssembly "system.xml"
            --Create an xml document object.
            xmlDoc = dotNetObject "system.xml.xmlDocument"            
            -- Create a root element for the xml doc and add it to the xmlDocument.
            root = xmlDoc.createElement "RedHalo_Max_to_Blender_Convert"            
            xmlDoc.appendChild root

            SettingElement = xmlDoc.CreateElement "Setting"
            root.appendChild SettingElement
            
            ObjectListElement = xmlDoc.createElement "ObjectList"
            root.appendChild ObjectListElement
            
            CameraListElement = xmlDoc.createElement "CameraList"
            root.appendChild CameraListElement
            
            LightListElement = xmlDoc.createElement "LightList"
            root.appendChild LightListElement
            
            MaterialList = xmlDoc.createElement "MaterialList"
            root.appendChild MaterialList

            ProxyListElement = xmlDoc.CreateElement "Proxy"
            root.appendChild ProxyListElement
            
            EnvironmentElement = xmlDoc.CreateElement "Environment"
            root.appendChild environmentElement

            -- holdMaxFile()
            SceneMaterial = GetSceneMaterials()
            print ("当前场景中共有 " + SceneMaterial.count as string + " 个材质")
            -- 场景清理
            DuplicateObjectNam()
            CleanUpMaterials()
            
            ResetGroupPivot()
            ClearUserProp()
            ShapeToPoly()
            DeleteEmptyPoly()

            -- CleanUpUnShpae()
            if export_proxy do ExportProxy xmlDoc ProxyListElement

            ExportSetting xmlDoc SettingElement
            ExportLight xmlDoc LightListElement
            ExportCamera xmlDoc CameraListElement
            ExportEnvironment xmlDoc EnvironmentElement
            -- 强制更新场景材质
            saveNodes #() (export_path + "rh-empty.max")

            -- 删除相机和灯光
            cams = Cameras as Array
            delete cams
            alllight = Lights as Array
            delete alllight

            -- 清理材质管理器
            CleanMeditSlot()

            -- 处理重名材质
            -- MakeUniqueMaterialName()
            
            -- for cls in material.classes do (
            for i in SceneMaterial do (
                cls = classof i
                if cls == VRay2SidedMtl do (
                    SideMtl = xmlDoc.createElement "DoubleSideMtl"
                    MaterialList.appendChild sideMtl

                    sideMtl.setAttribute "name" i.name
                    for p in (getPropNames i) do (
                        att = getProperty i p
                        sideMtl.setAttribute p (att as string)

                        CreateElement xmlDoc sideMtl att
                    )
                )
                -- VrayOverrideMtl List
                if cls == VRayOverrideMtl do (
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

                -- VrayMtl List
                if cls == VRayMtl do (                   
                    SingleMtl = xmlDoc.createElement "SingleMtl"
                    MaterialList.appendChild singleMtl

                    SingleMtl.setAttribute "name" i.name
                    useRoughness = getProperty i "brdf_useRoughness"
                    SingleMtl.setAttribute "useRoughness" (useRoughness as string)

                    -- LockIOR使用折射的IOR，否则就使用反射的IOR
                    lockIOR = true
                    lockIOR = getProperty i "reflection_lockior"
                    ior = 1.6
                    metallic_value = 0
                    useIOR = getProperty i "reflection_fresnel"
                        
                    if lockIOR then (
                        ior = getProperty i "refraction_ior"
                    )else(
                        ior = getProperty i "reflection_ior"
                    )

                    if useIOR == false then (
                        ior = 3
                    ) 

                    -- 如果IOR值高于5，设置Metallic为真
                    if ior > 5 then (
                        metallic_value = 1.0
                        ior = 1.6
                    )

                    for idx = 1 to NodeNames.count do (
                        propName = NodeNames[idx]

                        _node = xmlDoc.CreateElement propName
                        SingleMtl.appendChild _node

                        PropsArray = VR_PropsArray[idx]
                        NodeName = NodeAttribNames[idx]

                        num = 0
                                            
                        for prop in PropsArray do (
                            num += 1
                            value = ""
                            texture = getProperty i prop
                            value = texture 
                                
                            if (prop == "Reflection") or (prop == "Refraction") or (prop == "sheen_color") do (
                                value = (texture.v / 255.0) 
                            )

                            -- 设置IOR值
                            if (prop == "reflection_ior") do (
                                value = ior
                            )
                            -- 设置Metallic
                            if (prop == "reflection_metalness") do (
                                value = metallic_value
                            )
                            
                            _node.setAttribute NodeName[num] (value as string)
                            
                            CreateElement xmlDoc _node texture
                        )
                    )
                )

                -- VRayLightMtl
                if cls == VRayLightMtl do (
                    LightMtl = xmlDoc.CreateElement "LightMtl"
                    MaterialList.appendChild LightMtl
                    LightMtl.setAttribute "name" i.name

                    --VrayLightProps = #( "color" ,"multiplier" ,"texmap" ,"texmap_on" ,"twoSided" ,"compensate_exposure" ,"opacity_multiplycolor" ,"opacity_texmap" ,"opacity_texmap_on" ,"directLight_on" ,"directLight_subdivs" ,"directLight_cutoffThreshold" ,"displacement_multiplier" ,"displacement_texmap" ,"displacement_texmap_on" ,"texmap_resolution" ,"texmap_adaptiveness"
                    VrayLightProps = #("color" ,"multiplier" ,"texmap" , "texmap_on", "opacity_texmap" , "opacity_texmap_on", "twoSided")  

                    --for idx = 1 to NodeNames.count do (
                    for p in VrayLightProps do (
                        att = getProperty i p
                        LightMtl.setAttribute p (att as string)
                        
                    )

                    LightMap = xmlDoc.CreateElement "Lightmap"
                    LightMtl.appendChild Lightmap
                    tex = getProperty i "texmap" 
                    CreateElement xmlDoc LightMap tex

                    OpacityMap = xmlDoc.CreateElement "Opacitymap"
                    LightMtl.appendChild OpacityMap
                    tex = getProperty i "opacity_texmap"
                    CreateElement xmlDoc OpacityMap tex
                )

                -- CoronaMtl
                -- CoronaLegacyMtl
                if cls == CoronaMtl do (
                    SingleMtl = xmlDoc.createElement "SingleMtl"
                    MaterialList.appendChild singleMtl

                    SingleMtl.setAttribute "name" i.name

                    for idx = 1 to NodeNames.count do (
                        NodeName = NodeNames[idx]

                        node = xmlDoc.CreateElement NodeName
                        SingleMtl.appendChild node

                        PropsArray = CR_NodeProps[idx]
                        NodeName = NodeAttribNames[idx]

                        num = 0

                        for prop in PropsArray do (
                            num += 1
                            value = ""
                            texture = getProperty i prop
                            value = texture 
                            
                            if (prop == "colordiffuse") do (
                                fac = getProperty i #levelDiffuse
                                value *= fac
                            )
                            
                            if (prop == "colorreflect") do (
                                fac = getProperty i #levelReflect
                                value = (texture.v / 255.0) * fac
                            )
                            
                            if (prop == "colorrefract") do (
                                fac = getProperty i #levelrefract
                                value = (texture.v / 255.0) * fac
                            )
                            
                            if (prop == "colorOpacity") do (
                                fac = getProperty i #levelOpacity
                                value  *= fac
                            )

                            -- 设置IOR值
                            if (prop == "reflection_ior") do (
                                -- value = ior
                            )
                            -- 设置Metallic
                            if (prop == "reflection_metalness") do (
                                -- value = metallic_value
                            )

                            _node.setAttribute NodeName[num] (value as string)
                            
                            CreateElement xmlDoc _node texture
                        )
                    )
                )
                -- CoronaLightMtl
                if cls == CoronaLightMtl do (
                    LightMtl = xmlDoc.CreateElement "LightMtl"
                    MaterialList.appendChild LightMtl
                    LightMtl.setAttribute "name" i.name

                    --LigthProp = #(#intensity, #texmapOn, #texmap, #color, #affectAlpha, #occludeOther, #emitLight, #visibleRefl, #visibleDirect, #visibleRefract, #opacitytexmap, 
                    --            #opacityTexmapOn, #directionality, #excludeList, #excludeListIncludeMod, #visibleInMasks, #shadowcatcherIlluminator, #twosidedEmission, #legacyMode, #displayWire, \
                    --            #gBufferOverride, #nondirectionalFake, #visibleCaustics )
                    LightAttNames = #("color" ,"multiplier" ,"texmap" , "texmap_on", "opacity_texmap" ,"opacity_texmap_on","twoSided")    
                    LightProps = #(#color, #intensity, #texmap, #texmapOn, #opacitytexmap, #opacityTexmapOn, #twosidedEmission)
                    
                    for c = 1 to LightProps.count do (
                        att_name = LightAttNames[c]
                        p = LightProps[c]
                        att = getProperty i p
                        -- if p == 
                        LightMtl.setAttribute att_name (att as string)
                    )

                    LightMap = xmlDoc.CreateElement "Lightmap"
                    LightMtl.appendChild Lightmap
                    tex = getProperty i "texmap"
                    CreateElement xmlDoc LightMap tex

                    OpacityMap = xmlDoc.CreateElement "Opacitymap"
                    LightMtl.appendChild OpacityMap
                    tex = getProperty i "opacitytexmap"
                    CreateElement xmlDoc OpacityMap tex
                )                
            )
            -- if et_folder.text != "" do export_path = et_folder.text
            try(xmlDoc.Save (export_path + xmlname))catch()
            try(xmlDoc.Save ("D:\\xml_Temp.xml"))catch() --测试文件，方便查看
            xmlDoc = undefined
            
            --------FBX EXPORT-----
            pluginManager.loadClass FBXEXP
            --Geometry------------------------------------------------------------------------
            FBXExporterSetParam "SmoothingGroups" RedHalo_Exp_SmoothGroup
            FBXExporterSetParam "NormalsPerPoly" false
            FBXExporterSetParam "TangentSpaceExport" true
            FBXExporterSetParam "SmoothMeshExport" false
            FBXExporterSetParam "Preserveinstances" true
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
            case MaxVer of 
            (
                -- 3dsmax 2022
                24000: ( FBXExporterSetParam "FileVersion" "FBX202200" )
                -- 3dsmax 2021
                23000: ( FBXExporterSetParam "FileVersion" "FBX202100" )
                -- 3dsmax 2020
                22000: ( FBXExporterSetParam "FileVersion" "FBX202000" )
                -- 3dsmax 2019
                21000: ( FBXExporterSetParam "FileVersion" "FBX201900" )
                -- 3dsmax 2018
                20000: ( FBXExporterSetParam "FileVersion" "FBX201800" )
                -- 3dsmax 2017
                19000: ( FBXExporterSetParam "FileVersion" "FBX201700" )
                -- 3dsmax 2016
                18000: ( FBXExporterSetParam "FileVersion" "FBX201600" )	
            )
            -----------------------------------------------------------------------------------	
            fbx = export_path + fbxname

            if export_mode == 1 then (
                exportFile fbx #noPrompt selectedOnly:true	usage:FBXEXP
            )else(
                exportFile fbx #noPrompt selectedOnly:false	usage:FBXEXP
            )
            
            -- fetchMaxFile quiet:true
            messageBox "导出成功，请在Blender中用插件导入" tiltle:"Red Halo M2B"
        )
    )

    createDialog M2B width:400
)