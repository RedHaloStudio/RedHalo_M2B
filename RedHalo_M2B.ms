(
    /*
    * @Author: RedHalo Studio 
    * @Date: 2022-02-20 16:44:09 
    * @Last Modified by: RedHaloStudio
    * @Last Modified time: 2022-02-20 16:51:01
    */

    /*------------------------------------------------------
    --------------------------------------------------------
    ------------------------------------------------------*/
    fn rescaleObjects = (
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

    fn ConvertProxy = (
        for cls in GeometryClass.classes do (
            if cls == VRayProxy do (
                for i in getClassInstances VRayProxy do (
                    i.display = 4
                )
            )

            if cls == CoronaProxy do (
                for i in getClassInstances CoronaProxy do (
                    -- i.display = 4
                )
            )
        )
    )

    ---------Function BEGIN------------
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

    fn FixDuplicatName array obj =(
        if appendIfUnique array obj.name == false then (
            newname = obj.name + "_" + timeStamp() as string
            obj.name = newname
            FixDuplicatName array obj
        )
    )

    fn DuplicateObjectNam = (
        FixObjNames = #() 
        for i in objects do (
            FixDuplicatName FixObjNames i
        )
    )
    -------------------------
    --- 处理重名材质名字
    --- Unique Material Name
    fn MakeUniqueMaterialName =(
        AllMaterialName = #()
        for cls in material.classes do (
            for i in getClassInstances cls do (
                FixDuplicatName AllMaterialName i
            )
        )
    )
    --处理重名材质结束
    -----------------------


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


    fn SetColor parentNode prop_name clr = (
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

    fn FixTexture texture = (
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
                    save bm
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
            default:(
                return undefined
            )
        )
    )

    fn VRayBitmap_to_Bitmap vb = (
        bm = Bitmaptexture filename:vb.HDRIMapName
        replaceinstances vb bm
    )

    fn Convert_CoronaBitmap_to_Bitmap cb = (

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

    --整理所有材质
    fn CleanUpMaterials = (    
            
        for i in getClassInstances VRayOverrideMtl do (
            _t = i.baseMtl
            replaceinstances i _t
        )
        for i in getClassInstances VRayBlendMtl do (
            _t = i.baseMtl
            replaceinstances i _t
        )
        
        for i in getClassInstances VrayMtlWrapper do (
            _t = i.baseMtl
            replaceinstances i _t
        )

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

    )

    fn ShapeToPoly = (
        for i in Shapes do (
            if i.render_renderable == true do (
                convertToPoly i
            )
        )
    )

    fn CleanUpUnShpae = (
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

    fn DeleteEmptyPoly = (
        sel = #()
        for i in Geometry do 
        (
            try(if getNumFaces i == 0 then append sel i)catch()
        )
        delete sel
    )

    fn ResetGroupPivot = (
        for i in objects do (
            if isGroupHead i do (
                CenterPivot i
            )
        )
    )

    fn ClearUserProp = (
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

    /*------------------------------------------------------
    --------------------- GLOBAL VARS ----------------------
    ------------------------------------------------------*/

    fn CreateXML = (
        --Load the xml assembly
        dotNet.loadAssembly "system.xml"
        --Create an xml document object.
        xmlDoc = dotNetObject "system.xml.xmlDocument"
        
        -- Create a root element for the xml doc and add it to the xmlDocument.
        root = xmlDoc.createElement "RedHalo_Max_to_Blender_Convert"
        
        xmlDoc.appendChild root
        
        -- Global Setting
        SettingElement = xmlDoc.CreateElement "Setting"
        root.appendChild SettingElement
        
        -- NodeListElement = xmlDoc.createElement "NodeList"
        -- root.appendChild NodeListElement
        
        CameraListElement = xmlDoc.createElement "CameraList"
        root.appendChild CameraListElement
        
        LightListElement = xmlDoc.createElement "LightList"
        root.appendChild LightListElement
        
        MaterialList = xmlDoc.createElement "MaterialList"
        root.appendChild MaterialList

        return xmlDoc
    )

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
        )
    )

    fn ExportSetting ParentNode = (

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

    fn ExportLight ParentNode = (
        
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

    fn ExportCamera ParentNode = (
        -- Camera List
        for i in Cameras do (
            if classof i != TargetObject do (
                name = i.name
                fov = i.fov as string
                matrix = i.transform
                nearclip = 1
                farclip = 1000

                case classof i of (
                    Targetcamera:(
                        nearclip = i.nearclip
                        farclip = i.farclip
                    )
                    Freecamera:(
                        nearclip = i.nearclip
                        farclip = i.farclip
                    )
                    Physical:(
                        nearclip = i.near_clip
                        farclip = i.far_clip
                    )
                    VRayPhysicalCamera:(
                        nearclip = i.clip_near
                        farclip = i.clip_far
                    )
                    CoronaCam:(
                        nearclip = i.clippingNear
                        farclip = i.clippingFar
                    )
                )

                cameraList = xmlDoc.createElement "Camera"
                cameraList.setAttribute "name" name
                cameraList.setAttribute "fov" fov
                cameraList.setAttribute "near" (nearclip as string)
                cameraList.setAttribute "far" (farclip as string)
                cameraList.setAttribute "matrix" (matrix as string)
                ParentNode.appendChild cameraList
            )
        )
    )

    fn ExportEnvironment ParentNode = (
        Environment = xmlDoc.CreateElement "Environment"
        ParentNode.appendChild Environment

        DemoLights = for i in Lights where classof i == Skylight collect i

        for i in Lights do (
            if classof i == VRayLight do (
                if i.type == 1 do (
                    append DemoLights i
                )
            )
        )

        if DemoLights.count > 0 do (

        )

    )
    /*-------------------------------------
    ---------- FUNCTION END ---------------
    -------------------------------------*/

    /*
    *    UI
    */
    try(DestroyDialog M2B) catch()

    rollout M2B "Export2Blender(20220222)-RedHalo Studio(发霉的红地蛋)"
    (
        local RedHalo_Exp_SmoothGroup = true
        local RedHalo_Exp_Animation = false
        local RedHalo_Exp_Cameras = false
        local RedHalo_Exp_Lights = false
        local xmlname = "RH_M2B.xml"
        local fbxname = "RH_M2B.fbx"
        local filepath = sysInfo.tempdir
        local export_mode = 0

        local Material_List = #()

        local CR_Diffuse = #(#colordiffuse, #texmapDiffuse)
        local VR_Diffuse = #("Diffuse", "texmap_diffuse")
        local DiffuseAttrib = #("Color", "Texmap")

        local CR_Metallic = #(#reflection_metalness, #texmap_metalness)
        local VR_Metallic = #(#reflection_metalness, #texmap_metalness)
        local MetallicAttrib = #("Amount", "Texmap")

        local CR_Reflect = #(#colorreflect, #texmapReflect)
        local VR_Reflect = #("Reflection",  "texmap_reflection")
        local ReflectAttrib = #("Amount", "Texmap")

        local CR_Roughness = #(#reflectGlossiness, #texmapReflectGlossiness)
        local VR_Roughness = #("reflection_Glossiness", "texmap_reflectionGlossiness")
        local RoughnessAttrib = #("Amount", "Texmap")

        local CR_Anisotropy = #(#anisotropy, #texmapOnAnisotropy)
        local VR_Anisotropy = #("anisotropy", "texmap_anisotropy")
        local AnisotropyAttrib = #("Amount", "Texmap")

        local CR_AnisotropyRotation = #(#anisotropyRotation, #texmapOnAnisotropyRotation)
        local VR_AnisotropyRotation = #("anisotropy_rotation",  "texmap_anisotropy_rotation")
        local AnisotropyRotationAttrib = #("Amount", "Texmap")

        local CR_Sheen = #()
        local VR_Sheen = #("sheen_color", "texmap_sheen")
        local SheenAttrib = #("Amount", "Texmap")

        local CR_Coat = #()
        local VR_Coat = #("coat_amount", "texmap_coat_color")
        local CoatAttrib = #("Amount", "Texmap")

        local CR_CoatRoughness = #()
        local VR_CoatRoughness = #("coat_glossiness", "texmap_coat_glossiness")
        local CoatRoughnessAttrib = #("Amount", "Texmap")

        local CR_IOR = #(#fresnelIor, #texmapfresnelior)
        local VR_IOR = #( "reflection_ior", "texmap_reflectionior") --"refraction_ior", "texmap_refractionIOR", "texmap_reflectionior", "reflection_lockior")
        local IORAttrib = #("Amount", "Texmap")

        local CR_Refract = #(#levelrefract, #texmapRefract)
        local VR_Refract = #("Refraction", "texmap_refraction")
        local RefractAttrib = #("Amount", "Texmap")

        local CR_RefractRoughness = #(#refractGlossiness, #texmapRefractGlossiness)
        local VR_RefractRoughness = #("refraction_glossiness", "texmap_refractionGlossiness")
        local RefractRoughnessAttrib = #("Amount", "Texmap")

        local CR_Emission = #(#COLORSELFILLUM, #texmapSelfIllum)
        local VR_Emission = #("selfIllumination", "texmap_self_illumination")
        local EmissionAttrib = #("Color", "Texmap")

        local CR_EmissionStrength = #(#LEVELSELFILLUM)
        local VR_EmissionStrength = #("selfIllumination_multiplier", "texmap_self_illumination_multiplier")
        local EmissionStrengthAttrib = #("Amount", "Texmap")

        local CR_Opacity = #(#texmapOpacity)
        local VR_Opacity = #("texmap_opacity")
        local OpacityAttrib = #("Texmap")

        local CR_Bump = #(#mapamountBump, #texmapBump)
        local VR_Bump = #("texmap_bump_multiplier", "texmap_bump")
        local BumpAttrib = #("Amount", "Texmap")

        local CR_Translucent = #(#texmaptranslucency)
        local VR_Translucent = #("texmap_translucent")
        local TranslucentAttrib = #("Texmap")

        local CR_Displacement = #(#displacementMaximum, #texmapdisplace)
        local VR_Displacement = #("texmap_displacement_multiplier", "texmap_displacement")
        local DisplacementAttrib = #("Amount", "Texmap")

        local BitmapProps = #("clipu", "clipv", "clipw", "cliph", "alphasource", "filename")
        local CoordsProps = #("U_Tile", "V_Tile", "U_Tiling", "V_Tiling", "U_Offset", "V_Offset", "W_Angle", "V_Angle", "U_Angle")

        local CheckerProps = #("color1", "color2", "map1", "map2", "map1Enabled", "map2Enabled")

        -- Node Array ---
        local NodeNames = #("Diffuse", "Metallic", "Reflection", "Roughness", "Anisotropic", "AnisotropicRotation", "Sheen", "Coat", "CoatRoughness", "IOR", "Refraction", "RefractRoughness", "Emission", "EmissionStrength", "Opacity", "Bump", "Translucent", "Displacement")
        local VR_PropsArray = #(VR_Diffuse, VR_Metallic, VR_Reflect, VR_Roughness, VR_Anisotropy, VR_AnisotropyRotation, VR_Sheen, VR_Coat, VR_CoatRoughness, VR_IOR, VR_Refract, VR_RefractRoughness, VR_Emission, VR_EmissionStrength, VR_Opacity, VR_Bump, VR_Translucent, VR_Displacement)
        local CR_PropsArray = #(CR_Diffuse, CR_Metallic, CR_Reflect, CR_Roughness, CR_Anisotropy, CR_AnisotropyRotation, CR_Sheen, CR_Coat, CR_CoatRoughness, CR_IOR, CR_Refract, CR_RefractRoughness, CR_Emission, CR_EmissionStrength, CR_Opacity, CR_Bump, CR_Translucent, CR_Displacement)

        -- VR_NodeProps = #(DiffuseProps)
        local NodeAttribNames = #(DiffuseAttrib, MetallicAttrib, ReflectAttrib, RoughnessAttrib, AnisotropyAttrib, AnisotropyRotationAttrib, SheenAttrib, CoatAttrib, CoatRoughnessAttrib, IORAttrib, RefractAttrib, RefractRoughnessAttrib, EmissionAttrib, EmissionStrengthAttrib, OpacityAttrib, BumpAttrib, TranslucentAttrib, DisplacementAttrib)

        groupBox gb1 "导出选项" width:300 height:65 pos:[5,5]
        checkbutton cb_export_all "所有物体" checked:true height:40 width:145 pos:[10,20] tooltip:"导出场景中所有物体"
        checkbutton cb_export_sel "选择物体" checked:false height:40 width:145 pos:[155,20] tooltip:"导出场景中选择的物体"

        groupBox gb2 "模型选项" width:300 height:60 pos:[5, 75] enabled:false
        checkbutton cb_m_fbx_smoothGroup "Smoothing Groups" checked:true height:20 width:170 pos:[15, 90] enabled:false
        -- checkbutton cb_m_fbx_camera "Camera" checked:true height:20 width:170 pos:[15, 120] enabled:false
        -- checkbutton cb_m_fbx_Lights "Lights" checked:true height:20 width:170 pos:[15, 140] enabled:false
        checkbutton cb_m_fbx_Animation "Animation" checked:true height:20 width:170 pos:[15, 110] enabled:false
        -- checkbutton cb_m_fbx_ConvertUnit "Convert Unit" checked:true height:20 width:170 pos:[15, 180] enabled:false 
        
        groupbox gb3 "导出文件位置" width:300 height:60 pos:[5, 140]
        -- edittext et_folder "" width:270 pos:[5, 182] readonly:true enabled:false
        -- button btn_folder "..." width:20 height:20 pos:[275, 180]
        button btn_folder "" width:290 height:30 pos:[10, 160] border:false tooltip:"点击选择导出目录" enabled:false

        button btn_export "导出" width:85 height:120 pos:[310,10]
        button btn_about "?" width:85 height:30 pos:[310, 130]  tooltip:"帮助说明"

        on M2B open do (
            export_path = ""
            registry.openKey HKEY_CURRENT_USER "SOFTWARE\\REDHALO" accessRights:#all key:&key1
            if key1 != undefined then
                registry.queryValue key1 "Export" type:#REG_SZ value:&export_path expand:false
            
            btn_folder.text = export_path

            AllMats = #()
            for cls in material.classes do (
                if cls != Multimaterial do (
                    for m in getClassInstances cls do (
                        append AllMats m
                    )
                )
            )

            for m in AllMats do (
                if matchPattern (classof m as string) pattern:"vray*" == false do (
                    messageBox "暂时只支持Vray，请使用Vray自带的转换工具或是其它工具转换一下材质。"
                    return false
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
            xmlDoc = CreateXML()
            
            -- holdMaxFile()

            -- 场景清理
            DuplicateObjectNam()

            -- 处理场景不可用的纹理类型
            for cls in material.classes do (
                if cls == VRayBitmap do (
                    for i in getClassInstances VRayBitmap do (
                        try(VRayBitmap_to_Bitmap i) catch( print ("ERROR :" + i as string))
                    )
                )
            )

            CleanUpMaterials()
            
            ResetGroupPivot()
            ClearUserProp()
            ShapeToPoly()
            DeleteEmptyPoly()
            -- CleanUpUnShpae()
            ConvertProxy()

            ExportSetting SettingElement
            ExportLight LightListElement
            ExportCamera CameraListElement
            -- 强制更新场景材质
            saveNodes #() (filepath + "rh-empty.max")

            -- 删除相机和灯光
            cams = Cameras as Array
            delete cams
            alllight = Lights as Array
            delete alllight

            -- 清理材质管理器
            CleanMeditSlot()

            -- 处理重名材质
            MakeUniqueMaterialName()
            
            for cls in material.classes do (
                --------------------------------
                ------ 复合材质列表
                -- Vray2SidedMtl List
                if cls == VRay2SidedMtl do (
                    for i in getClassInstances VRay2SidedMtl do (
                        for m in refs.dependents i do (
                            if superClassOf m == GeometryClass do (
                                
                                SideMtl = xmlDoc.createElement "DoubleSideMtl"

                                MaterialList.appendChild sideMtl

                                sideMtl.setAttribute "name" i.name
                                for p in (getPropNames i) do (
                                    att = getProperty i p
                                    sideMtl.setAttribute p (att as string)

                                    CreateElement xmlDoc sideMtl att
                                )
                            )
                        )
                    )
                )
                -- VrayOverrideMtl List
                if cls == VRayOverrideMtl do (
                    for i in getClassInstances VrayOverrideMtl do (
                        for m in refs.dependents i do (
                            if superClassOf m == GeometryClass do (
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
                        )
                    )
                )
                -----复合材质列表 结束
                -----------------------

                ------------------------
                ------ 基础材质节点列表
                -- VrayMtl List
                if cls == VRayMtl do (
                    for i in getClassInstances VrayMtl do (

                        -- 只把场景中使用的材质导出

                        for v in refs.dependents i do (
                            if superClassOf v == GeometryClass do (

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
                        )

                    )
                )

                -- VRayLightMtl
                if cls == VRayLightMtl do (
                    for i in getClassInstances VrayLightMtl do (
                        for m in refs.dependents i do (
                            if superClassOf m == GeometryClass do (
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
                        )
                    )
                )

                -- CoronaMtl
                -- CoronaLegacyMtl
                if cls == CoronaMtl do (
                    for i in getClassInstances CoronaMtl do (
                        for m in refs.dependents i do (
                            if superClassof m == GeometryClass do (

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
                        )
                    )
                )
                -- CoronaLightMtl
                if cls == CoronaLightMtl do (
                    for i in getClassInstances CoronaLightMtl do (
                        for m in refs.dependents i do (
                            if superClassof m == GeometryClass do (
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
                    )
                )
                
            )
            -- if et_folder.text != "" do filepath = et_folder.text
            print filepath
            xmlDoc.Save (filepath + xmlname)
            xmlDoc.Save ("D:\\xml_Temp.xml") --测试文件，方便查看
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