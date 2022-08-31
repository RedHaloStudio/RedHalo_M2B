 --macroScript RedHalo_Tools
 --category:"Red Halo"
 --toolTip:"Red Halo Export2Blender"
(
    _version = "0.6"
    _author = "RedHalo Studio(发霉的红地蛋)"
    _data = "2022-08-29"
    _copyright = "(c) 2022 RedHalo Studio. All rights reserved."
    _title = "RedHalo Max2Blender"

    GUID = dotNetClass "System.Guid"
    
    Global AssetHashCode = #()
    Global AssetPath = #()

    findClasses = #(
        #(Bitmaptexture, #filename),
        #(VRayBitmap, #HDRIMapName),
        #(VRayProxy, #filename),
        #(CProxy, #filename),
        #(VRayIES, #ies_file),
        #(CoronaLight, #iesfile),
        #(Free_Point, #webfile),
        #(Target_Light, #webfile),
        #(CoronaBitmap, #filename)      
    )
    
    function KelvinToRGB Kelvin = (
        ---- Kelvin Table ,From 1000 to 12000
        kelvin_table = #((color 255 56 0), (color 255 71 0), (color 255 83 0), (color 255 93 0), (color 255 101 0), (color 255 109 0), (color 255 115 0), (color 255 121 0), (color 255 126 0), \
                        (color 255 131 0), (color 255 138 18), (color 255 142 33), (color 255 147 44), (color 255 152 54), (color 255 157 63), (color 255 161 72), (color 255 165 79), (color 255 169 87),\
                        (color 255 173 94), (color 255 177 101), (color 255 180 107), (color 255 184 114), (color 255 187 120), (color 255 190 126), (color 255 193 132), (color 255 196 137), (color 255 199 143), \
                        (color 255 201 148), (color 255 204 153), (color 255 206 159), (color 255 209 163), (color 255 211 168), (color 255 213 173), (color 255 215 177), (color 255 217 182), (color 255 219 186), \
                        (color 255 221 190), (color 255 223 194), (color 255 225 198), (color 255 227 202), (color 255 228 206), (color 255 230 210), (color 255 232 213), (color 255 233 217), (color 255 235 220), \
                        (color 255 236 224), (color 255 238 227), (color 255 239 230), (color 255 240 233), (color 255 242 236), (color 255 243 239), (color 255 244 242), (color 255 245 245), (color 255 246 247), \
                        (color 255 248 251), (color 255 249 253), (color 254 249 255), (color 252 247 255), (color 249 246 255), (color 247 245 255), (color 245 243 255), (color 243 242 255), (color 240 241 255), \
                        (color 239 240 255), (color 237 239 255), (color 235 238 255), (color 233 237 255), (color 231 236 255), (color 230 235 255), (color 228 234 255), (color 227 233 255), (color 225 232 255), \
                        (color 224 231 255), (color 222 230 255), (color 221 230 255), (color 220 229 255), (color 218 229 255), (color 217 227 255), (color 216 227 255), (color 215 226 255), (color 214 225 255), \
                        (color 212 225 255), (color 211 224 255), (color 210 223 255), (color 209 223 255), (color 208 222 255), (color 207 221 255), (color 207 221 255), (color 206 220 255), (color 205 220 255), \
                        (color 207 218 255), (color 207 218 255), (color 206 217 255), (color 205 217 255), (color 204 216 255), (color 204 216 255), (color 203 215 255), (color 202 215 255), (color 202 214 255), \
                        (color 201 214 255), (color 200 213 255), (color 200 213 255), (color 199 212 255), (color 198 212 255), (color 198 212 255), (color 197 211 255), (color 197 211 255), (color 197 210 255), \
                        (color 196 210 255), (color 195 210 255), (color 195 209 255))

        idx = 10
        if Kelvin < 1000 then Kelvin = 1000
        if Kelvin > 12000 do Kelvin = 12000
        idx = (Kelvin / 100) as Integer
        return kelvin_table[idx - 9]
    )

    function HexToRGB HEX = (
        str = ""
        if findString HEX "#" != undefined then (
            str = substring HEX 2 HEX.count
        ) else (
            str = HEX
        )

        r = bit.HexAsInt (substring str 1 2)
        g = bit.HexAsInt (substring str 3 4)
        b = bit.HexAsInt (substring str 5 6)
        return (color r g b)

    )

    function GetHashCode SourceString = (
        md = dotnetObject "System.Security.Cryptography.MD5CryptoServiceProvider"
        ue =  dotNetObject "System.Text.ASCIIEncoding"
        bytesToHash = ue.GetBytes SourceString
        hash = md.ComputeHash bytesToHash
    
        MD5_STR = ""
        for i in hash do (
            MD5_STR += toUpper (bit.intAsHex i)
        )
        
        return MD5_STR
    )

    function FixSafeName oldname =(
        oldname = dotNetObject "System.string" oldname

        newname = oldname.Replace " " "_"
        newname = (dotNetObject "System.string" newname).Replace "#" "_"
        newname = (dotNetObject "System.string" newname).Replace "-" "_"
        newname = (dotNetObject "System.string" newname).Replace "." "_"
        newname = (dotNetObject "System.string" newname).Replace ":" "_"
        newname = (dotNetObject "System.string" newname).Replace ";" "_"
        newname = (dotNetObject "System.string" newname).Replace "," "_"
        newname = (dotNetObject "System.string" newname).Replace "!" "_"
        newname = (dotNetObject "System.string" newname).Replace "?" "_"
        newname = (dotNetObject "System.string" newname).Replace "~" "_"
        newname = (dotNetObject "System.string" newname).Replace "`" "_"
        newname = (dotNetObject "System.string" newname).Replace "^" "_"
        newname = (dotNetObject "System.string" newname).Replace "&" "_"
        newname = (dotNetObject "System.string" newname).Replace "*" "_"
        newname = (dotNetObject "System.string" newname).Replace "|" "_"
        newname = (dotNetObject "System.string" newname).Replace "\\" "_"
        newname = (dotNetObject "System.string" newname).Replace "\"" "_"
        newname = (dotNetObject "System.string" newname).Replace "'" "_"
        newname = (dotNetObject "System.string" newname).Replace ">" "_"
        newname = (dotNetObject "System.string" newname).Replace "<" "_"
        newname = (dotNetObject "System.string" newname).Replace "=" "_"
        
        return newName
    )

    -- 获取场景中所有材质，包括子材质。
    function GetSceneMaterials = (
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
                    _tmp_name = FixSafeName i.name
                    
                    i.name = _tmp_name
                    if appendIfUnique AllSceneMaterialsName i.name then (
                        append AllSceneMaterials i
                    ) else (
                        uid = (GUID.NewGuid()).ToString("N")
                        uniqueName_tmp = toUpper uid
                        i.name = i.name + "_" + (substring uniqueName_tmp 1 8)
                        append AllSceneMaterials i
                    )
                )
            )
        )
        return AllSceneMaterials
    )

    function ConvertGamma acolor gamma = (
        r = (acolor.r / 255.0) ^ gamma * 255
        g = (acolor.g / 255.0) ^ gamma * 255
        b = (acolor.b / 255.0) ^ gamma * 255
        
        return (color r g b)
    )

    function FBXText2Hex s = (
        local ch = "abcdefghijklmnopqrstuvwxyz123456789_ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        local hex = ""
        for i=1 to s.count do
            if (findString ch s[i] == undefined) then
                hex += "FBXASC0"+(bit.charAsInt s[i]) as string
            else
                hex += s[i]	
        return hex
    )

    function RescaleObjects = (
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

    function CleanMeditSlot = (
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
    
    function ShapeToPoly = (
        for i in Shapes do (
            if i.render_renderable == true do (
                convertToPoly i
            )
        )
    )
    
    function CleanUpUnShpae = (
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
    
    function DeleteEmptyPoly = (
        sel = #()
        for i in Geometry do 
        (
            try(if getNumFaces i == 0 then append sel i)catch()
        )
        delete sel
    )
    
    -- 重置组的轴心位置
    function ResetGroupPivot = (
        groups = for i in objects where isGroupHead i collect i
        for i in groups do (
            -- CenterPivot i
            ResetPivot i
        )
    )
    
    -- 清理用户属性，blender不支持fbx用户属性
    function ClearUserProp = (
        for i in objects do (
            setUserPropBuffer i ""
        )
    )
    
    -- 写入注册表，保存输出路径
    function setRegistryKey key subkey val = (
        registry.openKey HKEY_CURRENT_USER key accessRights:#all key:&key1
        registry.createKey HKEY_CURRENT_USER key accessRights:#all newKeyCreated:&newKeyCreated key:&key1
        registry.setValue key1 subkey #REG_SZ val
    )

    -- 自动修正错误路径
    function RetargetPath = (
        scenefilename = maxfilepath + maxFileName

        oldfilenames = #()
        newfilenames = #()

        for i = 1 to AssetManager.GetNumAssets() do
        (
            local AUIO = AssetManager.GetAssetByIndex i
            local Asset_ID = AUIO.GetAssetId()
            local Asset_Filename = AUIO.getfilename()
            local Asset_Type = AUIO.gettype()
            
            append oldfilenames Asset_Filename

            FileResolutionManager.getFullFilePath &Asset_Filename Asset_Type            
            append newfilenames Asset_Filename
        )

        for cls in findClasses do (
            if cls[1] != undefined do (
                clsInstance = getClassInstances cls[1]                
                for i in clsinstance do (				
                    old_filename = getProperty i cls[2]                    
                    ind = findItem oldfilenames old_filename
                    if ind != 0 do (
                        setProperty i cls[2] newfilenames[ind]
                    )
                )
            )
        )
    )

    -- 清理纹理
    function CleanupTexture texture = (
        type = classof texture
        
        case type of (
            Mix:(
                texture.map1 = CleanupTexture texture.map1
                texture.map2 = CleanupTexture texture.map2
                texture.mask = CleanupTexture texture.mask

                if not texture.map1Enabled do texture.map1 = undefined
                if not texture.map2Enabled do texture.map2 = undefined
                if not texture.maskEnabled do texture.mask = undefined

                return texture
            )

            Checker:(
                texture.map1 = CleanupTexture texture.map1
                texture.map2 = CleanupTexture texture.map2

                if not texture.map1Enabled do texture.map1 = undefined
                if not texture.map2Enabled do texture.map2 = undefined

                return texture
            )

            ColorCorrection:(
                texture.map = CleanupTexture texture.map
                return texture
            )

            CompositeTexturemap:(
                return CleanupTexture texture.maplist[1]
            )

            Mask:(
                texture.map = CleanupTexture texture.map
                texture.mask = CleanupTexture texture.mask

                if not texture.mapEnabled do texture.map = undefined
                if not texture.maskEnabled do texture.mask = undefined
            )

            Bitmaptexture:(
                tex_filename = texture.filename

                if tex_filename == undefined or tex_filename == "" or (not doesFileExist tex_filename)  then (
                    texture = undefined
                ) else (

                    tex_name = texture.name
                    tex_mode_on = texture.apply
                    tex_clip_u = texture.clipu
                    tex_clip_v = texture.clipv
                    tex_clip_width = texture.clipw
                    tex_clip_height = texture.cliph

                    tex_width = texture.bitmap.width
                    tex_height = texture.bitmap.height

                    filepath = getFilenamePath tex_filename
                    filename = getFilenameFile tex_filename
                    filetype = getFilenameType tex_filename
                    
                    Asset_Hash_Str = StringStream ""
                    HashCode = ""
                    format "FILENAME:%s,WIDTH:%,HEIGHT:%,CLIPU:%,CLIPV:%,CLIPW:%,CLIPH:%" tex_filename tex_width tex_height tex_clip_u tex_clip_v tex_clip_width tex_clip_height to:Asset_Hash_Str
                    HashCode = GetHashCode Asset_Hash_Str
                    

                    local bm = undefined
                    uid = (GUID.NewGuid()).toString("N")
                    uniqueName_tmp = toUpper uid

                    if tex_mode_on and ( tex_clip_width < 1 or tex_clip_height < 1 ) then (
                        tex_width = tex_width * tex_clip_width
                        tex_height = tex_height * tex_clip_height
                        
                        tex_clip_u = 0
                        tex_clip_v = 0
                        tex_clip_width = 1
                        tex_clip_height = 1

                        ind = findItem AssetHashCode HashCode
                        bm = Bitmaptexture filename:tex_filename
                        bm.name = tex_name

                        if ind == 0 then (
                            newfilename = filepath + filename + "_" + (substring uniqueName_tmp 1 8) + filetype
                            NewBitmap = renderMap texture size:[tex_width, tex_height] filename:newfilename
                            try( save NewBitmap )catch()
                            close NewBitmap

                            append AssetHashCode HashCode
                            append AssetPath newfilename
                        ) else (
                            file = AssetPath[ind]
                            bm.filename = file
                        )
                        texture = bm
                    )else(
                        format "FILENAME:%s,WIDTH:%,HEIGHT:%,CLIPU:%,CLIPV:%,CLIPW:%,CLIPH:%" tex_filename tex_width tex_height tex_clip_u tex_clip_v tex_clip_width tex_clip_height to:Asset_Hash_Str
                        HashCode = GetHashCode Asset_Hash_Str
                        
                        append AssetHashCode HashCode
                        append AssetPath tex_filename
                    )
                )
            )

            Falloff:(
                texture.map1 = CleanupTexture texture.map1
                texture.map2 = CleanupTexture texture.map2
                return texture
            )

            Gradient:(
                /*
                texture.map1 = CleanupTexture texture.map1
                texture.map2 = CleanupTexture texture.map2
                texture.map3 = CleanupTexture texture.map3
                return texture
                */
                file_path = maxfilepath
                if file_path == "" do (
                    file_path = GetDir #image
                )
                uid = (GUID.NewGuid()).toString("N")
                uniqueName_tmp = toUpper uid

                tex_name = "GRAD_" + (substring uniqueName_tmp 1 8)
                
                tex_filename = file_path + tex_name + ".jpg"
                
                NewBitmap = renderMap texture size:[512, 512] filename:tex_filename
                try(
                    save NewBitmap 
                    close NewBitmap
                    
                    bm = Bitmaptexture filename:tex_filename
                    bm.name = tex_name
                    return bm
                )catch(
                    return undefined
                )
                
            )

            Gradient_Ramp:(
                file_path = maxfilepath
                if file_path == "" do (
                    file_path = GetDir #image
                )
                uid = (GUID.NewGuid()).toString("N")
                uniqueName_tmp = toUpper uid

                tex_name = "GRAD_" + (substring uniqueName_tmp 1 8)
                
                tex_filename = file_path + tex_name + ".jpg"
                
                NewBitmap = renderMap texture size:[512, 512] filename:tex_filename
                try(
                    save NewBitmap 
                    close NewBitmap
                    
                    bm = Bitmaptexture filename:tex_filename
                    bm.name = tex_name
                    return bm
                )catch(
                    return undefined
                )

            )

            RGB_Multiply:(
                texture.map1 = CleanupTexture texture.map1
                texture.map2 = CleanupTexture texture.map2

                if not texture.map1Enabled do texture.map1 = undefined
                if not texture.map2Enabled do texture.map2 = undefined

                return texture
            )

            Tiles:(
                texture.Mortar_Map = CleanupTexture texture.Mortar_Map
                texture.Bricks_Map = CleanupTexture texture.Bricks_Map
                return texture
            )

            Cellular:(
                return CleanupTexture texture.cellMap
            )

            ColorMap:(
                if texture.map != undefined then (
                    tmp = texture.map
                    return tmp
                )else(
                    return texture
                )

            )
            
            Vertex_Color:(
                return texture
            )

            ----- VRay Textures
            VRayBitmap:(
                tex_filename = texture.HDRIMapName
                tex_name = texture.name
                tex_mode_on = texture.cropplace_on
                tex_mode_type = texture.cropplace_mode
                tex_clip_width = texture.cropplace_width
                tex_clip_height = texture.cropplace_height
                
                bm = undefined
                
                if tex_filename == undefined then (				
                    texture = undefined
                ) else (    
                    SourceBitmap = Bitmaptexture filename:tex_filename
                    SourceBitmap.name = tex_name

                    tex_width = SourceBitmap.bitmap.width
                    tex_height = SourceBitmap.bitmap.height
                    
                    filepath = getFilenamePath tex_filename
                    filename = getFilenameFile tex_filename
                    filetype = getFilenameType tex_filename

                    if tex_mode_on or (tex_clip_width < 1 or tex_clip_height < 1) then (
                        newfile = filepath + filename + "_crop" + filetype
                        nb = renderMap texture size:[tex_width * tex_clip_width, tex_height * tex_clip_height] filename:newfile
                        
                        try(save nb)catch()
                        close nb
                        
                        bm = Bitmaptexture filename:newfile
                        bm.name = tex_name                        
                    ) else (	
                        bm = SourceBitmap
                    )			
                    
                    -- replaceInstances texture bm
                )
                texture = bm
            )

            VRayBump2Normal:(
                texture.bump_map = CleanupTexture texture.bump_map
                return texture.bump_map
            )

            VRayColor2Bump:(
                texture.map = CleanupTexture texture.map
                return texture
            )

            VRayCompTex:(
                return CleanupTexture texture.sourcea
            )

            VRayDirt:(
                texture.texmap_occluded_color = CleanupTexture texture.texmap_occluded_color
                texture.texmap_unoccluded_color = CleanupTexture texture.texmap_unoccluded_color
                texture.texmap_radius = CleanupTexture texture.texmap_radius
                
                return texture
            )

            VRayMultiSubTex:(
                return CleanupTexture texture.default_texmap
            )

            VRayTriplanarTex:(
                return CleanupTexture texture.texture
            )

            VRayNormalMap:(
                texture.normal_map = CleanupTexture texture.normal_map
                texture.bump_map = CleanupTexture texture.bump_map
                return texture
            )

            VRayColor:(
                return texture
            )

            VRayUserScalar:(
                tex = texture.default_texmap
                if texture.default_texmap_on and (tex != undefined) then (
                    return (CleanupTexture tex)
                ) else (
                    return undefined
                )
            )

            VRayUserColor:(
                tex = texture.default_texmap
                clr = texture.default_color

                cm = ColorMap solidColor:clr map:(CleanupTexture tex) Gamma:1
                return cm
            )

            -- CORONA TEXTURES
            CoronaBitmap:(
                tex_filename = texture.filename
                tex_ClipOn = texture.clippingOn
                tex_ClipMode = texture.ClippingMode
                tex_ClipU = texture.clippingU
                tex_ClipV = texture.clippingV
                tex_ClipWidth = texture.clippingWidth
                tex_ClipHeight = texture.clippingHeight
                tex_UVWScale = texture.uvwScale
                tex_name = texture.name
                
                bm = undefined
                
                if tex_filename == undefined then (
                    return undefined
                ) else (
                    SourceBitmap = Bitmaptexture filename:tex_filename
                    SourceBitmap.name = texture.name

                    tex_width = SourceBitmap.bitmap.width
                    tex_height = SourceBitmap.bitmap.height

                    filepath = getFilenamePath tex_filename
                    filename = getFilenameFile tex_filename
                    filetype = getFilenameType tex_filename
    
                    if tex_ClipOn or (tex_ClipWidth < 1 or tex_ClipHeight < 1) then (
                        newfile = filepath + filename + "_crop" + filetype
                        nb = renderMap texture size:[tex_width * tex_clipWidth, tex_height * tex_ClipHeight] filename:newfile
                        
                        try(
                            save nb
                            close nb                            
                            bm = Bitmaptexture filename:newfile
                            bm.name = tex_name
                        )catch()
                    ) else (
                        bm = SourceBitmap
                    )                    
                )
                return bm
            )

            CoronaUvwRandomizer:(
                if texture.input == undefined then (
                    return undefined
                ) else (
                    tex = CleanupTexture texture.input
                    return tex
                )
            )

            CoronaTriplanar:(
                tex = texture.texmapX

                if tex == undefined then (
                    return undefined
                ) else (
                    _tex = CleanupTexture tex
                    return _tex
                )
            )

            CoronaTonemapControl:(
                tex = texture.inputTexmap

                if tex == undefined then (
                    return undefined
                ) else (
                    _tex = CleanupTexture tex
                    return _tex
                )
            )

            CoronaSelect:(
                selected = texture.selected
                tex = texture.texmaps[selected]

                if tex == undefined then (
                    return undefined
                ) else (
                    _tex = CleanupTexture tex
                    return _tex
                )
            )

            CoronaRaySwitch:(
                tex = texture.giColor
                if tex == undefined then (
                    return undefined
                ) else (
                    _tex = CleanupTexture tex
                    return _tex
                )
            )

            CoronaMultiMap:(
                tex = texture.texmaps[1]

                cm = ColorMap solidColor:texture.colors[1]

                if tex != undefined then (
                    _tex = CleanupTexture tex
                    return _tex
                ) else (
                    return cm
                )
            )

            CoronaFrontBack:(
                tex_f = texture.frontTexmap
                tex_b = texture.backTexmap

                tex = undefined

                if texture.frontTexmapOn do texture.frontTexmap = undefined
                if texture.backTexmapOn do texture.backTexmap = undefined

                if tex_f != undefined then (                    
                    tex = CleanupTexture tex_f
                ) else (
                    tex = ColorMap solidColor:texture.frontColor
                )

                return tex
            )

            CoronaBumpConverter:(
                texture.input = CleanupTexture texture.input
                return texture
                
            )

            CoronaAO:(
                tex_Occluded = texture.texmapOccluded
                tex_Unoccluded = texture.texmapUnoccluded
                tex_Distance = texture.texmapDistance

                if texture.texmapOccludedOn then (
                    texture.texmapOccluded = CleanupTexture tex_Occluded
                ) else (
                    texture.texmapOccluded = undefined
                )

                if texture.texmapUnoccludedOn then (
                    texture.texmapUnoccluded = CleanupTexture tex_Unoccluded
                ) else (
                    texture.texmapUnoccluded = undefined
                )

                if texture.texmapDistanceOn then (
                    texture.texmapDistance = CleanupTexture tex_Distance
                ) else (
                    texture.texmapDistance = undefined
                )

                return texture
            )

            CoronaMix:(
                tex_top = texture.texmapTop
                tex_bottom = texture.texmapBottom
                tex_mix = texture.texmapMix

                if texture.texmapMixOn then (
                    texture.texmapMix = CleanupTexture tex_mix
                ) else (
                    texture.texmapMix = undefined
                )

                if texture.texmapTopOn then (
                    texture.texmapTop = CleanupTexture tex_top
                ) else (
                    texture.texmapTop = undefined
                )

                if texture.texmapBottomOn then (
                    texture.texmapBottom = CleanupTexture tex_bottom
                ) else (
                    texture.texmapBottom = undefined
                )

                return texture

            )

            CoronaColor:(
                inputIsLinear = texture.inputIsLinear
                method = texture.method
                FinalClr = White
                case method of (
                    0:(
                        clr = texture.color
                        if inputIsLinear then (
                            FinalClr = ConvertGamma clr  (1/2.2)                    
                        ) else (
                            FinalClr = clr
                        )
                    )
                    1:(
                        colorHdr = texture.colorHdr
                        r = 255
                        g = 255
                        b = 255
                        if r = colorHDR[1] > 1 then r = 255 else r = colorHDR[1]*255
                        if g = colorHDR[2] > 1 then r = 255 else r = colorHDR[2]*255
                        if b = colorHDR[3] > 1 then r = 255 else r = colorHDR[3]*255

                        _c = color r g b

                        if inputIsLinear then (
                            FinalClr = ConvertGamma _c (1/2.2)
                        ) else (
                            FinalClr = _c
                        )
                    )
                    2:(
                        temperature = texure.temperature
                        _c = KelvinToRGB temperature

                        if inputIsLinear then (
                            FinalClr = ConvertGamma _c (1/2.2)
                        ) else (
                            FinalClr = _c
                        )
                    )
                    3:(
                        hexColor = texture.hexColor
                        _c = HEXToRGB hexcolor

                        if inputIsLinear then (
                            FinalClr = ConvertGamma _c (1/2.2)
                        ) else (
                            FinalClr = _c
                        )
                    )
                )
                cm = ColorMap solidColor:FinalClr
                return cm
            )

            CoronaColorCorrect:(
                tex = texture.inputTexmap
                ctrlSource = texture.controlsSource
                tex_name = texture.name
                filepath = maxfilepath
                tex_filename = ""

                tex_type = classof tex
                if (tex_type == Bitmaptexture ) or (tex_type == VRayBitmap) or (tex_type == CoronaBitmap) then (
                    if tex_type == Bitmaptexture do tex_filename = tex.filename
                    if tex_type == VRayBitmap do tex_filename = tex.HDRIMapName
                    if tex_type == CoronaBitmap do tex_filename = tex.filename
                ) else (
                    if filepath == "" then (
                        filepath = GetDir #image
                    )
                    filename = filepath + "RH.jpg"
                )

                filepath = getFilenamePath tex_filename
                filename = getFilenameFile tex_filename
                filetype = getFilenameType tex_filename                               

                local bm = undefined
                uid = (GUID.NewGuid()).toString("N")
                uniqueName_tmp = toUpper uid

                if ctrlSource == 0 then (
                    if texture.curveEnabled or texture.temperature != 6500 or texture.greenMagentaTint != 0 or texture.exposure != 0 or texture.lutEnable then (
                        -- 重新渲染一张新贴图
                        newfilename = filepath + filename + "_" + (substring uniqueName_tmp 1 8) + filetype
                        NewBitmap = renderMap texture size:[512, 512] filename:newfilename
                        try(
                            save NewBitmap 
                            close NewBitmap
                            texture = Bitmaptexture filename:newfilename
                        )catch(
                            texture = undefined
                        )
                    ) else (
                        texture.inputTexmap = CleanupTexture tex
                    )
                ) else (
                    -- 重新渲染一张新贴图
                    newfilename = filepath + filename + "_" + (substring uniqueName_tmp 1 8) + filetype
                    NewBitmap = renderMap texture size:[512, 512] filename:newfilename
                    try(
                        save NewBitmap 
                        close NewBitmap
                        texture = Bitmaptexture filename:newfilename
                    )catch(
                        texture = undefined
                    )
                )

                return texture
            )

            CoronaNormal:(
                tex = texture.normalMap
                addition_tex = texture.additionalBump
                if tex == undefined then (
                    texture = undefined
                ) else (
                    texture.normalMap = CleanupTexture tex
                )

                if texture.additionalBumpOn then (
                    texture.additionalBump = CleanupTexture addition_tex
                ) else (
                    texture.additionalBump = undefined
                )

                return texture
            )

            -- OTHERS
            default: (
                texture = undefined
            )
        )
        return texture
    )

    -- 整理材质
    function CleanupMaterial mat = (
        MAT_Type = classof mat
        
        case MAT_Type of (
            VRayBlendMtl:(
                /*
                for i = 1 to 9 do (
                    tex = mat.texmap_blend[i]				
                    mat.texmap_blend[i] = CleanupTexture tex
                )
                */
                _t = VrayMtl name:mat.name
                if mat.baseMtl != undefined then (
                    _t = mat.baseMtl
                    _t.name = mat.name
                )else(
                    for i = 1 to 9 do (
                        if mat.coatmtl[i] != undefined do (
                            _t = mat.coatmtl[i]
                            _t.name = mat.name
                            break
                        )
                    )
                )
                replaceinstances mat _t
            )
            /*
            VRayMtl:(
                for p in getPropNames mat do (
                    a = getProperty mat p
                    if(superclassof a == textureMap) do (
                        setProperty mat p (CleanupTexture a)
                    )
                )
            )
            */
            VRay2SidedMtl:(
                mat.texmap_translucency = CleanupTexture mat.texmap_translucency
            )

            VRayOverrideMtl:(
                _t = VRayMtl name:mat.name
                if mat.baseMtl != undefined then (
                    _t = mat.baseMtl
                    _t.name = mat.name
                )                
                replaceinstances mat _t
            )
            
            VrayMtlWrapper:(
                name = mat.name
                _t = VRayMtl name:name
                if mat.baseMtl != undefined do (
                    _t = mat.baseMtl
                    _t.name = name
                )
                replaceinstances mat _t
            )

            DoubleSided:(
                map1_on = getProperty mat "map1Enabled"
                map2_on = getProperty mat "map2Enabled"
                mat_name = mat.name

                _mtl = mat

                if not (map1_on and map2_on) then (
                    if not map1_on do (
                        _mtl = getProperty mat "material1"
                        _mtl.name = mat_name
                    )

                    if not map2_on do (
                        _mtl = getProperty mat "material2"
                        _mtl.name = mat_name
                    )

                    replaceInstances mat _mtl
                )
            )

            CoronaMtl:(
                for p in getPropNames mat do (
                    a = getProperty mat p
                    if(superclassof a == textureMap) do (
                        setProperty mat p (CleanupTexture a)
                    )
                )
            )

            CoronaRaySwitchMtl:(
                _t = mat.gimtl
                mat_name = mat.name

                replaceInstances mat _t
            )

            CoronaLayeredMtl:(
                _t = mat.basemtl
                _mat_name = mat.name

                replaceInstances mat _t
            )
            
            default:(
                for p in getPropNames mat do (
                    a = getProperty mat p
                    if(superclassof a == textureMap) do (
                        setProperty mat p (CleanupTexture a)
                    )
                )
            )
        )
    )

    -- 导出物体动画
    function ExportAnimate obj start end = (
        transform_array = ""
        for t = start to end do (
            at time t (
                tmp = "@" + obj.transform as string
                transform_array += tmp
            )
        )
        return transform_array
    )

    -- 修复重复的物体名称
    function FixDuplicatName array obj =(
        if appendIfUnique array obj.name == false then (
            uid = (GUID.NewGuid()).toString("N")
            uniqueName_tmp = toUpper uid
            newname = obj.name + "_" + (substring uniqueName_tmp 1 8)
            obj.name = newname
            FixDuplicatName array obj
        )
    )

    -- 设置物体的轴心
    function SetPivot obj Pivot:2 = (
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

    -- 修复整个场景中的物体名字
    function DuplicateObjectNam = (
        local FixObjNames = #() 
        for i in objects do (
            FixDuplicatName FixObjNames i
        )
    )

    -- Remove Proxy's modifier
    function removeProxyModifier obj = (
        if (classof obj.baseobject == VRayProxy) or (classof obj.baseobject == CoronaProxy) do (
            if obj.modifiers.count > 0 do (
                for i = 1 to obj.modifiers.count do (
                    DeleteModifier obj i
                )
            )
        )
    )

    /*
    *    UI
    */
    try(DestroyDialog ::M2B) catch()

    rollout M2B "Export2Blender-RedHalo Studio(发霉的红地蛋)"
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

        global VR_Diffuse = #("Diffuse", "texmap_diffuse")
        global DiffuseAttrib = #("Color", "Texmap")

        global VR_Metallic = #(#reflection_metalness, #texmap_metalness)
        global MetallicAttrib = #("Amount", "Texmap")

        global VR_Reflect = #("Reflection",  "texmap_reflection")
        global ReflectAttrib = #("Amount", "Texmap")

        global VR_Roughness = #("reflection_Glossiness", "texmap_reflectionGlossiness")
        global RoughnessAttrib = #("Amount", "Texmap")

        global VR_Anisotropy = #("anisotropy", "texmap_anisotropy")
        global AnisotropyAttrib = #("Amount", "Texmap")

        global VR_AnisotropyRotation = #("anisotropy_rotation",  "texmap_anisotropy_rotation")
        global AnisotropyRotationAttrib = #("Amount", "Texmap")

        global VR_Sheen = #("sheen_color", "texmap_sheen")
        global SheenAttrib = #("Amount", "Texmap")

        global VR_Coat = #("coat_amount", "texmap_coat_color")
        global CoatAttrib = #("Amount", "Texmap")

        global VR_CoatRoughness = #("coat_glossiness", "texmap_coat_glossiness")
        global CoatRoughnessAttrib = #("Amount", "Texmap")

        global VR_IOR = #( "reflection_ior", "texmap_reflectionior") --"refraction_ior", "texmap_refractionIOR", "texmap_reflectionior", "reflection_lockior")
        global IORAttrib = #("Amount", "Texmap")

        global VR_Refract = #("Refraction", "texmap_refraction")
        global RefractAttrib = #("Amount", "Texmap")

        global VR_RefractRoughness = #("refraction_glossiness", "texmap_refractionGlossiness")
        global RefractRoughnessAttrib = #("Amount", "Texmap")

        global VR_Emission = #("selfIllumination", "texmap_self_illumination")
        global EmissionAttrib = #("Color", "Texmap")

        global VR_EmissionStrength = #("selfIllumination_multiplier", "texmap_self_illumination_multiplier")
        global EmissionStrengthAttrib = #("Amount", "Texmap")

        global VR_Opacity = #("texmap_opacity_multiplier", "texmap_opacity")
        global OpacityAttrib = #("Amount", "Texmap")

        global VR_Bump = #("texmap_bump_multiplier", "texmap_bump")
        global BumpAttrib = #("Amount", "Texmap")

        global VR_Translucent = #("texmap_translucent")
        global TranslucentAttrib = #("Texmap")

        global VR_Displacement = #("texmap_displacement_multiplier", "texmap_displacement")
        global DisplacementAttrib = #("Amount", "Texmap")

        global BitmapProps = #("clipu", "clipv", "clipw", "cliph", "alphasource", "filename")
        global CoordsProps = #("U_Tile", "V_Tile", "U_Tiling", "V_Tiling", "U_Offset", "V_Offset", "W_Angle", "V_Angle", "U_Angle", "MappingType", "Mapping")

        global CheckerProps = #("color1", "color2", "map1", "map2", "map1Enabled", "map2Enabled")

        -- Node Array ---
        global NodeNames = #("Diffuse", "Metallic", "Reflection", "Roughness", "Anisotropic", "AnisotropicRotation", "Sheen", "Coat", "CoatRoughness", "IOR", "Refraction", "RefractRoughness", "Emission", "EmissionStrength", "Opacity", "Bump", "Translucent", "Displacement")
        global VR_PropsArray = #(VR_Diffuse, VR_Metallic, VR_Reflect, VR_Roughness, VR_Anisotropy, VR_AnisotropyRotation, VR_Sheen, VR_Coat, VR_CoatRoughness, VR_IOR, VR_Refract, VR_RefractRoughness, VR_Emission, VR_EmissionStrength, VR_Opacity, VR_Bump, VR_Translucent, VR_Displacement)

        -- VR_NodeProps = #(DiffuseProps)
        global NodeAttribNames = #(DiffuseAttrib, MetallicAttrib, ReflectAttrib, RoughnessAttrib, AnisotropyAttrib, AnisotropyRotationAttrib, SheenAttrib, CoatAttrib, CoatRoughnessAttrib, IORAttrib, RefractAttrib, RefractRoughnessAttrib, EmissionAttrib, EmissionStrengthAttrib, OpacityAttrib, BumpAttrib, TranslucentAttrib, DisplacementAttrib)
        local MixName = #("Color1", "Color2", "MixAmount", "Texmap1", "Texmap2", "TexmapMask", "MixMode")

        dotnetcontrol lb_0 "System.Windows.Forms.Label" text:"【必须】安装对应的VRay或Corona渲染器" height:25 width:360 pos:[5, 10]
        dotnetcontrol lb_1 "System.Windows.Forms.Label" text:"【必须】VRay或Corona英文版（包括破解版）" height:25 width:360 pos:[5, 30]	
        button btn_about "?" width:20 height:50 pos:[375, 5]  tooltip:"帮助说明"

        groupBox gb1 "导出选项" width:390 height:65 pos:[5, 60]
        checkbutton cb_export_all "所有物体" checked:true height:40 width:190 pos:[10,80] tooltip:"导出场景中所有物体"
        checkbutton cb_export_sel "选择物体" checked:false height:40 width:190 pos:[200,80] tooltip:"导出场景中选择的物体"

        groupBox gb2 "模型选项" width:390 height:65 pos:[5, 130] enabled:false
        checkbutton cb_m_fbx_smoothGroup "Smoothing Groups" checked:true height:20 width:170 pos:[15, 150] enabled:false
        -- checkbutton cb_m_fbx_camera "Camera" checked:true height:20 width:170 pos:[15, 120] enabled:false
        -- checkbutton cb_m_fbx_Lights "Lights" checked:true height:20 width:170 pos:[15, 140] enabled:false
        checkbutton cb_m_fbx_Animation "Animation" checked:true height:20 width:170 pos:[15, 170] --enabled:false
        -- checkbutton cb_m_fbx_ConvertUnit "Convert Unit" checked:true height:20 width:170 pos:[15, 180] enabled:false

        -- groupbox gb3 "导出文件位置(空为默认地址)" width:300 height:60 pos:[5, 140]
        -- edittext et_folder "" width:270 pos:[5, 182] readonly:true enabled:false
        -- button btn_folder "..." width:20 height:20 pos:[275, 180]
        -- button btn_folder "" width:290 height:30 pos:[10, 160] border:false tooltip:"点击选择导出目录" enabled:false

        dotnetcontrol btn_export "button" text:"E X P O R T" width:390 height:50 pos:[5, 210]
        label lbl "(C)2022 RedHalo Studio" height:30 pos:[150, 270]
        progressBar pb value:0 Color:Red height:8 width:390 pos:[5,290]
        ---------Function BEGIN----------------
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
        ------- Bitmap Node END -------------------
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

                    MixParams = #("color1", "Color2", "mixAmount", "map1", "map2", "Mask")
                    
                    for i = 1 to MixParams.count do(
                        att = getProperty Texture MixParams[i]
                        MixNode.setAttribute MixName[i] (att as string)
                    )

                    MixNode.setAttribute "MixMode" "MIX"

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
                    
                    map = getProperty Texture "map"
                    --- "LIGHTNESSMODE"
                    CCParams = #("color", "map", "HUESHIFT", "saturation", "BRIGHTNESS", "contrast", "GAMMARGB")--, "rewireMode")
                    CCNames = #("Color", "Map", "Hue", "Saturation", "Brightness", "Contrast", "Gamma")--, "ColorMode")
                    -- CC_Color_Mode = #("NORMAL", "INVERT", "MONO")
                    for i = 1 to CCParams.count do (
                        atts = getProperty Texture CCParams[i]
                        CCNode.setAttribute CCNames[i] (atts as string)
                    )

                    -- Color Mode
                    clrMode = getProperty texture "rewireMode"
                    case clrMode of (
                        0: CCNode.setAttribute "ColorMode" "NORMAL"
                        1: CCNode.setAttribute "ColorMode" "MONO"
                        2: CCNode.setAttribute "ColorMode" "INVERT"
                        default: CCNode.setAttribute "ColorMode" "NORMAL"
                    )

                    -- Set Gamma
                    CC_Mode = getProperty texture "lightnessMode"
                    gamma = getProperty texture "GAMMARGB"
                    if CC_Mode == 0 then (
                        CCNode.setAttribute "Gamma" "1.0"
                    ) else (
                        CCNode.setAttribute "Brightness" "0"
                        CCNode.setAttribute "Contrast" "0"
                    )

                    CCMap = xmlDoc.CreateElement "Map"
                    CCNode.appendChild CCMap
                    map = getProperty Texture "map"
                    CreateElement xmlDoc CCMap map

                )

                RGB_Multiply:(
                    Mix = xmlDoc.CreateElement "Mix"
                    ParentNode.appendChild Mix

                    mixParams = #(#color1, #color2, #map1, #map2, #mixOperation)
                    MixName = #("Color1", "Color2", "Texmap1", "Texmap2", "MixMode")

                    for i = 1 to mixParams.count do (
                        att = getProperty texture mixParams[i]
                        Mix.setAttribute mixName[i] (att as string)
                    )

                    mix.setAttribute "mixAmount" "1.0"
                    mix.setAttribute "MixMode" "MULTIPLY"
                    mix.setAttribute "TexmapMask" "undefined"

                    Map1 = xmlDoc.CreateElement "Map1"
                    Mix.appendChild Map1
                    Map1_tex = getProperty texture "map1"
                    CreateElement xmlDoc Map1 Map1_tex

                    Map2 = xmlDoc.CreateElement "Map2"
                    Mix.appendChild Map2
                    Map2_tex = getProperty texture "map2"
                    CreateElement xmlDoc Map2 Map2_tex

                    Mask = xmlDoc.CreateElement "Mask"
                    Mix.appendChild Mask
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

                ColorMap:(
                    map = getProperty texture "map"
                    mapEnabled = getProperty texture "mapEnabled"

                    if map != undefined and mapEnabled then (
                        CreateBitmapNode xmlDoc ParentNode Texture
                    ) else (
                        ColorMapNode = xmlDoc.CreateElement "Color"
                        ParentNode.appendChild ColorMapNode
                        
                        clr = getProperty texture "solidcolor"
                        gamma = getProperty texture "gamma"
                        
                        finalClr = ConvertGamma clr gamma
                        ColorMapNode.setAttribute "Color" (finalClr as string)
                    )
                )

                --- VRay Textures
                VrayDirt:(
                    Names = # ("OccludedColor", "UnoccludedColor", "Subdivs", "Mode", "OnlySameObject", "TexmapRadius", "TexmapOccluded", "TexmapUnoccluded")
                    Params = # ("occluded_color", "unoccluded_color", "subdivs", "mode", "consider_same_object_only", "texmap_radius", "texmap_occluded_color", "texmap_unoccluded_color")

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

                    AONode = xmlDoc.CreateElement "AO"
                    ParentNode.appendChild AONode

                    for i = 1 to Params.count do (
                        att = getProperty texture Params[i]
                        AONode.setAttribute Names[i] (att as string)
                    )

                    AO_Radius = getProperty texture "Radius"
                    AONode.setAttribute "Radius" ((AO_Radius * scaleFac) as string)

                    mode = getProperty texture "mode"
                    case mode of (
                        -- 0: AONode.setAttribute "Mode" "OUTSIDE"
                        4: AONode.setAttribute "Mode" "INSIDE"
                        default: AONode.setAttribute "Mode" "BOTH"
                    )

                    OccludedNode = xmlDoc.CreateElement "Occluded"
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

                Vertex_Color:(
                    VCNode = xmlDoc.CreateElement "VertexColor"
                    ParentNode.appendChild VCNode
                )

                VRayNormalMap:(
                    NormalNames = #("NormalMap", "BumpMap", "BumpStrength", "NormalStrength", "FlipRed", "FilpGreen", "SweepRedGreen")
                    params = #("normal_map", "bump_map", "bump_map_multiplier", "normal_map_multiplier", "flip_red", "flip_green", "swap_red_and_green")

                    BumpNode = xmlDoc.CreateElement "Normal"
                    ParentNode.appendChild BumpNode
                    
                    for i = 1 to params.count do (
                        att = getProperty texture params[i]
                        BumpNode.setAttribute NormalNames[i] (att as string)
                    )

                    MapNormalNode = xmlDoc.CreateElement "NormalMap"
                    BumpNode.appendChild MapNormalNode
                    map1 = getProperty texture "normal_map"
                    CreateElement xmlDoc MapNormalNode map1

                    MapBumpNode = xmlDoc.CreateElement "BumpMap"
                    BumpNode.appendChild MapBumpNode
                    map2 = getProperty texture "bump_map"
                    CreateElement xmlDoc MapBumpNode map2
                )

                VRayColor2Bump:(
                    BumpNode = xmlDoc.CreateElement "Normal"
                    ParentNode.appendChild BumpNode

                    BumpNode.setAttribute "NormalMap" "undefined"

                    map2 = getProperty texture "map"
                    BumpNode.setAttribute "BumpMap" (map2 as string)

                    BumpNode.setAttribute "BumpStrength" ((getProperty texture #height) as string)

                    BumpNode.setAttribute "NormalStrength" "1.0"
                    BumpNode.setAttribute "FlipRed" "false"
                    BumpNode.setAttribute "FilpGreen" "false"
                    BumpNode.setAttribute "SweepRedGreen" "false"                    

                    MapNormalNode = xmlDoc.CreateElement "NormalMap"
                    BumpNode.appendChild MapNormalNode

                    MapBumpNode = xmlDoc.CreateElement "BumpMap"
                    BumpNode.appendChild MapBumpNode
                    CreateElement xmlDoc MapBumpNode map2
                )

                VRayBump2Normal:(
                    BumpNode = xmlDoc.CreateElement "Normal"
                    ParentNode.appendChild BumpNode
                    
                    BumpNode.setAttribute "NormalMap" "undefined"

                    map2 = getProperty texture "bump_map"
                    BumpNode.setAttribute "BumpMap" (map2 as string)

                    BumpNode.setAttribute "BumpStrength" "0.3"

                    BumpNode.setAttribute "NormalStrength" "1.0"
                    BumpNode.setAttribute "FlipRed" "false"
                    BumpNode.setAttribute "FilpGreen" "false"
                    BumpNode.setAttribute "SweepRedGreen" "false"                    

                    MapNormalNode = xmlDoc.CreateElement "NormalMap"
                    BumpNode.appendChild MapNormalNode

                    MapBumpNode = xmlDoc.CreateElement "BumpMap"
                    BumpNode.appendChild MapBumpNode
                    CreateElement xmlDoc MapBumpNode map2
                )

                VRayBitmap:(
                    if texture.HDRIMapName != undefined then (
                        bm = Bitmaptexture filename:texture.HDRIMapName
                        CreateBitmapNode xmlDoc ParentNode bm
                    ) else (
                        bm = undefined
                    )                    
                )

                VRayColor:(
                    ColorNode = xmlDoc.CreateElement "Color"
                    ParentNode.appendChild ColorNode

                    clr = getProperty texture "color"
                    gamma = getProperty texture "color_gamma"

                    finalClr = ConvertGamma clr gamma
                    ColorNode.setAttribute "Color" (finalClr as string)
                )

                VRayCompTex:(
                    Mix = xmlDoc.CreateElement "Mix"
                    ParentNode.appendChild Mix

                    mixParams = #(#sourcea, #sourceb, #multiplier)
                    MixName = #( "Texmap1", "Texmap2", "MixAmount")

                    MixModeNames = #("ADD", "SUBTRACT", "DIFFERENCE", "MULTIPLY", "DIVIDE", "MINIMUM", "MAXIMUM", "COLORSHIFT", "COLORTINT", "BENDALPHASTRAIGHT", "BLENDAPLHAPREMULIPLIED")

                    mix.setAttribute "Color1" "(color 255 255 255)"
                    mix.setAttribute "Color2" "(color 255 255 255)"

                    for i = 1 to mixParams.count do (
                        att = getProperty texture mixParams[i]
                        Mix.setAttribute mixName[i] (att as string)
                    )
                    MIX.setAttribute "MixMode" MixModeNames[(getProperty texture #operator) + 1]
                    mix.setAttribute "TexmapMask" "undefined"

                    Map1 = xmlDoc.CreateElement "Map1"
                    Mix.appendChild Map1
                    Map1_tex = getProperty texture "sourcea"
                    CreateElement xmlDoc Map1 Map1_tex

                    Map2 = xmlDoc.CreateElement "Map2"
                    Mix.appendChild Map2
                    Map2_tex = getProperty texture "sourceb"
                    CreateElement xmlDoc Map2 Map2_tex

                    Mask = xmlDoc.CreateElement "Mask"
                    Mix.appendChild Mask
                )
                
                -- Corona Textures
                CoronaAO:(
                    params = #("colorOccluded", "colorUnoccluded", "samplesCount", "texmapDistance",  "texmapOccluded", "texmapUnoccluded")
                    names = #("OccludedColor", "UnoccludedColor", "Subdivs",  "TexmapRadius", "TexmapOccluded", "TexmapUnoccluded")
                    
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

                    AONode = xmlDoc.CreateElement "AO"
                    ParentNode.appendChild AONode

                    for i in 1 to params.count do (
                        att = getProperty texture params[i]
                        AONode.setAttribute names[i] (att as string)
                    )

                    AO_Radius = getProperty texture "maxDistance"
                    AONode.setAttribute "Radius" ((AO_Radius * scaleFac) as string)

                    mode = getProperty texture "normalMode"
                    case mode of (
                        -- 0: AONode.setAttribute "Mode" "OUTSIDE"
                        1: AONode.setAttribute "Mode" "INSIDE"
                        default: AONode.setAttribute "Mode" "BOTH"
                    )

                    ExcludeMode = getProperty texture "excludeMode"
                    if ExcludeMode == 3 then (
                        AONode.setAttribute "OnlySameObject" "true"
                    ) else (
                        AONode.setAttribute "OnlySameObject" "false"
                    )

                    OccludedNode = xmlDoc.CreateElement "Occluded"
                    UnoccludedNode = xmlDoc.CreateElement "Unoccluded"
                    RadiusNode = xmlDoc.CreateElement "Radius"

                    AONode.appendChild OccludedNode
                    OccludedMap = getProperty texture "texmapOccluded"
                    CreateElement xmlDoc OccludedNode OccludedMap

                    AONode.appendChild UnoccludedNode
                    UnoccludedMap = getProperty texture "texmapUnoccluded"
                    CreateElement xmlDoc UnoccludedNode UnoccludedMap

                    AONode.appendChild RadiusNode
                    RadiusMap = getProperty texture "texmapDistance"
                    CreateElement xmlDoc RadiusNode RadiusMap
                )

                CoronaMix:(
                    Mix = xmlDoc.CreateElement "Mix"
                    ParentNode.appendChild Mix

                    mixParams = #(#colorTop, #colorBottom, #mixAmount, #texmapTop, #texmapBottom, #texmapMix, #mixOperation)
                    CoronaMixMode = #("ADD", "SUBTRACT", "MULTIPLY", "DIVIDE", "MINIMUM", "MAXIMUM", "MIX", "GAMMA", "DIFFERENCE", "SCREEN", "OVERLAY", "DODGE", "BURN", "LINEARBURN", "LINEAR_LIGHT", "SOFT_LIGHT", "HARDLIGHT", "VIVIDLIGHT", "PINLIGHT", "HARDMIX", "EXCLUSION")

                    for i = 1 to mixParams.count do (
                        att = getProperty texture mixParams[i]
                        Mix.setAttribute mixName[i] (att as string)
                    )

                    mix.setAttribute "MixMode" CoronaMixMode[(getProperty texture "mixOperation")+1]

                    Map1 = xmlDoc.CreateElement "Map1"
                    Mix.appendChild Map1
                    Map1_tex = getProperty texture "texmapTop"
                    CreateElement xmlDoc Map1 Map1_tex

                    Map2 = xmlDoc.CreateElement "Map2"
                    Mix.appendChild Map2
                    Map2_tex = getProperty texture "texmapBottom"
                    CreateElement xmlDoc Map2 Map2_tex

                    Mask = xmlDoc.CreateElement "Mask"
                    Mix.appendChild Mask
                    Mask_tex = getProperty texture "texmapMix"
                    CreateElement xmlDoc Mask Mask_tex
                )

                CoronaColorCorrect:(
                    CCNode = xmlDoc.CreateElement "ColorCorrection"
                    ParentNode.appendChild CCNode 
                    
                    CCNode.setAttribute "Color" ("(color 0 0 0)")
                    --- "LIGHTNESSMODE"
                    CCParams = #("inputTexmap", "hue", "saturation", "brightness", "contrast", "gamma")--, "rewireMode")
                    CCNames = #("Map", "Hue", "Saturation", "Brightness", "Contrast", "Gamma")--, "ColorMode")
                    -- CC_Color_Mode = #("NORMAL", "INVERT", "MONO")
                    for i = 1 to CCParams.count do (
                        atts = getProperty Texture CCParams[i]
                        CCNode.setAttribute CCNames[i] (atts as string)
                    )

                    -- Color Mode
                    if getProperty texture "invert" then (
                        CCNode.setAttribute "ColorMode" "INVERT"
                    ) else (
                        CCNode.setAttribute "ColorMode" "NORMAL"
                    )

                    CCMap = xmlDoc.CreateElement "Map"
                    CCNode.appendChild CCMap
                    map = getProperty Texture "inputTexmap"
                    CreateElement xmlDoc CCMap map
                )

                CoronaNormal:(
                    Normal_Params = #("normalMap", "additionalBump", "additionalBumpStrength", "multiplier", "flipred", "flipgreen", "swapRedGreen")
                    NormalNames = #("NormalMap", "BumpMap", "BumpStrength", "NormalStrength", "FlipRed", "FilpGreen", "SweepRedGreen")

                    BumpNode = xmlDoc.CreateElement "Normal"
                    ParentNode.appendChild BumpNode
                    for i = 1 to Normal_Params.count do (
                        att = getProperty texture Normal_Params[i]
                        BumpNode.setAttribute NormalNames[i] (att as string)
                    )

                    MapNormalNode = xmlDoc.CreateElement "NormalMap"
                    BumpNode.appendChild MapNormalNode
                    map1 = getProperty texture "normalMap"
                    CreateElement xmlDoc MapNormalNode map1

                    MapBumpNode = xmlDoc.CreateElement "BumpMap"
                    BumpNode.appendChild MapBumpNode
                    map2 = getProperty texture "additionalBump"
                    CreateElement xmlDoc MapBumpNode map2

                )

                CoronaBumpConverter:(
                    BumpNode = xmlDoc.CreateElement "Normal"
                    ParentNode.appendChild BumpNode

                    BumpNode.setAttribute "NormalMap" "undefined"

                    map2 = getProperty texture "input"
                    BumpNode.setAttribute "BumpMap" (map2 as string)
                    
                    strength = getProperty texture #strength
                    BumpNode.setAttribute "BumpStrength" "0.3"

                    BumpNode.setAttribute "NormalStrength" "1.0"
                    BumpNode.setAttribute "FlipRed" "false"
                    BumpNode.setAttribute "FilpGreen" "false"
                    BumpNode.setAttribute "SweepRedGreen" "false"                    

                    MapNormalNode = xmlDoc.CreateElement "NormalMap"
                    BumpNode.appendChild MapNormalNode

                    MapBumpNode = xmlDoc.CreateElement "BumpMap"
                    BumpNode.appendChild MapBumpNode
                    CreateElement xmlDoc MapBumpNode map2
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
            Light_Type = #()

            for l in light.classes do (
                if l != Skylight do (
                    append Light_Type l
                )
            )

            for lt in Light_Type do (
                for l in getClassInstances lt do (
                    lights_array = #()

                    for l in refs.dependents l do (
                        if classof l == lt do (
                            if classof l == VRayLight then (
                                if l.type != 1 do (
                                    append lights_array l
                                )
                            ) else (
                                append lights_array l
                            )
                        )
                    )
                    -- print lights_array

                    if lights_array.count > 0 do (
                        LightsListItem = xmlDoc.CreateElement "LightItem"
                        ParentNode.appendChild LightsListItem                
                        
                        light_first = Lights_array[1]

                        -- Lights List
                        L_Color = "(color 255 255 255)"
                        L_Multiplier = "1"
                        L_Type = "AREA"
                        L_Length = 0.01
                        L_Width = 0.01
                        L_IES = "undefined"
                        L_Hotspot = "0"
                        L_Falloff = "45"
                        L_Invisible = false
                        L_Shadow = true
                        L_Diffuse = true
                        L_Specular = true
                        L_Reflection = true
                        L_Portal = false
        
                        case lt of (
                            Target_Light:(
                                L_Color = light_first.rgbFilter
                                L_Multiplier = light_first.intensity / 1000 
        
                                if light_first.Distribution == 3 do (
                                    L_Type = "POINT"
                                    L_IES = light_first.webfile
                                )
                                if light_first.Distribution == 1 do (
                                    L_Type = "SPOT"
                                    L_IES = "undefined"
                                    L_Hotspot = light_first.Hotspot
                                    L_Falloff = light_first.falloff
                                )
                                if light_first.Distribution == 2 or light_first.Distribution == 0 do (
                                    L_Type = "POINT"
                                    L_IES = "undefined"
                                )
                            )
                            Free_Light:(
                                L_Color = light_first.rgbFilter
                                L_Multiplier = light_first.intensity / 1000 
        
                                if light_first.Distribution == 3 do (
                                    L_Type = "POINT"
                                    L_IES = light_first.webfile
                                )
                                if light_first.Distribution == 1 do (
                                    L_Type = "SPOT"
                                    L_IES = "undefined"
                                    L_Hotspot = light_first.Hotspot
                                    L_Falloff = light_first.falloff
                                )
                                if light_first.Distribution == 2 or light_first.Distribution == 0 do (
                                    L_Type = "POINT"
                                    L_IES = "undefined"
                                )
                            )
                            targetSpot:(
                                L_Color = light_first.rgb
                                L_Multiplier = light_first.multiplier 
                                L_Type = "SPOT"
                                L_Hotspot = light_first.Hotspot
                                L_Falloff = light_first.falloff
                            )
                            freeSpot:(
                                L_Color = light_first.rgb
                                L_Multiplier = light_first.multiplier                     
                                L_Type = "SPOT"
                                L_Hotspot = light_first.Hotspot
                                L_Falloff = light_first.falloff
                            )
                            TargetDirectionallight:(
                                L_Color = light_first.rgb
                                L_Multiplier = light_first.multiplier 
                                L_Type = "SUN"
                            )
                            Directionallight:(
                                L_Color = light_first.rgb
                                L_Multiplier = light_first.multiplier 
                                L_Type = "SUN"
                            )
                            Omnilight:(
                                L_Color = light_first.rgb
                                L_Multiplier = light_first.multiplier 
                                L_Type = "POINT"
                            )
                            VRayLight:(
                                L_Color = light_first.color
                                L_Multiplier = light_first.multiplier
        
                                case light_first.type of (
                                    0: L_type = "AREA"
                                    2: L_Type = "POINT"
                                    4: L_Type = "DISK"
                                )
        
                                L_Length = light_first.sizeLength
                                L_Width = light_first.sizeWidth
                                L_Invisible = light_first.invisible
                                L_Shadow = light_first.castshadows
                                L_Diffuse = light_first.affect_diffuse
                                L_Specular = light_first.affect_specular
                                L_Reflection = light_first.affect_reflections
                                L_Portal = light_first.SkylightPortal
                            )
                            VRayIES: (
                                L_Color = light_first.color
                                L_Multiplier = light_first.power
                                L_Type = "POINT"
                                L_Length = 0.1
                                L_Width = 0.1
                                L_IES = light_first.ies_file
                                L_Invisible = ""
                                L_Diffuse = light_first.affect_diffuse
                                L_Shadow = light_first.cast_shadows
                                L_Specular = light_first.affect_specular
                                L_Reflections = true
                                L_Portal = false                     
                            )
                            VRaySun:(
                                L_Color = light_first.filter_Color
                                L_Multiplier = light_first.intensity_multiplier
                                L_type = "SUN"
                                L_Length = light_first.size_multiplier
                                L_Width = "0.1"
                                L_Invisible = light_first.invisible
                                L_Shadow = "true"
                                L_Diffuse = light_first.affect_diffuse
                                L_Specular = light_first.affect_specular
                                L_Reflection = "false"
                                L_Portal = "false"
                            )
                            CoronaLight:(
                                L_Mode = light_first.colormode

                                if L_Mode == 0 then (
                                    L_Color = light_first.color
                                ) else (
                                    L_Color = KelvinToRGB(light_first.blackbodytemp)
                                )

                                if light_first.on then (
                                    L_Multiplier = light_first.intensity
                                ) else (
                                    L_Multiplier = 0
                                )

                                LT_TYPE = light_first.shape
                                case LT_TYPE of (
                                    0: L_Type = "POINT"
                                    1: L_Type = "AREA"
                                    2: L_Type = "DISK"
                                    default: L_Type = "POINT"
                                )

                                L_Length = light_first.width
                                L_Width = light_first.height

                                if light_first.ieson and light_first.iesFile != undefined then (
                                    L_IES = light_first.iesFile
                                ) else (
                                    L_IES = "undefined"
                                )

                                L_Hotspot = "0"
                                L_Falloff = "45"
                                L_Invisible = light_first.visibledirectly
                                L_Shadow = true
                                L_Diffuse = true
                                L_Specular = light_first.visibleRefl
                                L_Reflection = light_first.visibleRefr
                                L_Portal = false
                            )
                            CoronaSun:(
                                L_Mode = light_first.colormode

                                case L_Mode of (
                                    2: L_Color = (color 255 255 255)
                                    0: L_Color = light_first.colordirect
                                    1: L_Color = KelvinToRGB(light_first.blackbodyTemperature)
                                )

                                if light_first.on then (
                                    L_Multiplier = light_first.intensity
                                ) else (
                                    L_Multiplier = 0
                                )

                                LT_TYPE = "SUN"
                                L_Length = light_first.sizemultiplier
                                L_IES = "undefined"                                

                                L_Hotspot = "0"
                                L_Falloff = "45"
                                L_Invisible = light_first.visibledirectly
                                L_Shadow = true
                                L_Diffuse = true
                                L_Specular = light_first.visibleRefl
                                L_Reflection = light_first.visibleRefr
                                L_Portal = false
                            )
                        )

                        LightsListItem.setAttribute "color" (L_Color as string)
                        LightsListItem.setAttribute "multiplier" (L_Multiplier as string)
                        LightsListItem.setAttribute "type" L_Type
                        LightsListItem.setAttribute "length" (L_Length as string)
                        LightsListItem.setAttribute "width" (L_Width as string)
                        LightsListItem.setAttribute "ies" (L_IES as string)
                        LightsListItem.setAttribute "hotspot" (L_Hotspot as string)
                        LightsListItem.setAttribute "falloff" (L_Falloff as string)
                        LightsListItem.setAttribute "portal" (L_Portal as string)
                        
                        for i in lights_array do (
                            LightsList = xmlDoc.CreateElement "Light"
                            LightsListItem.appendChild LightsList
                            
                            LightsList.setAttribute "name" i.name
                            LightsList.setAttribute "matrix" (i.transform as string)
                            LightsList.setAttribute "caseshadows" (L_Shadow as string)
                            LightsList.setAttribute "invisible" (L_Invisible as string)
                            LightsList.setAttribute "affectdiffuse" (L_Diffuse as string)
                            LightsList.setAttribute "affectspecular" (L_Specular as string)
                            LightsList.setAttribute "affectreflections" (L_Reflections as string)
                        )
                    )
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
                        --frame_xml = xmlDoc.CreateElement "frame"
                        --Transform_data_xml.appendChild frame_xml

                        --frame_xml.setAttribute "frame" (t as string)
                        --frame_xml.setAttribute "transform" (i.transform as string)
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
                uid = (GUID.NewGUID()).toString("N")
                uniqueName_tmp = toUpper uid
                newname = "P_" + (substring uniqueName_tmp 1 8) + "_" + proxy_name
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

        function ExportObject xmlDoc ParentNode = (
            -- 可渲染 Render
            --renderable
            -- 对相机可见 Camera
            --primaryVisibility
            -- 反射/折射见 Reflect
            --secondaryVisibility
            -- 产生阴影 Shadow
            --castShadows
            -- 大气影响 Atmospherics
            --ApplyAtmospherics

            for i in objects do (
                if (not i.renderable) or (not i.primaryVisibility) or (not i.secondaryVisibility) or (not i.castShadows) or (not i.applyAtmospherics) do (
                    ObjectNode = xmlDoc.CreateElement "Object"
                    ParentNode.appendChild ObjectNode
                    ObjectNode.setAttribute "name" i.name
                    ObjectNode.setAttribute "Render" (i.renderable as string)
                    ObjectNode.setAttribute "Camera" (i.primaryVisibility as string)
                    ObjectNode.setAttribute "Reflect" (i.secondaryVisibility as string)
                    ObjectNode.setAttribute "Shadow" (i.castShadows as string)
                    ObjectNode.setAttribute "Atmospherics" (i.ApplyAtmospherics as string)
                )
            )
        )

        /*-------------------------------------
        ---------- FUNCTION END ---------------
        -------------------------------------*/

        on M2B open do (
            M2B.title = _title + " - V" + _version

            -- set_export_path = ""
            -- registry.openKey HKEY_CURRENT_USER "SOFTWARE\\REDHALO" accessRights:#all key:&key1
            -- if key1 != undefined then
                -- registry.queryValue key1 "Export" type:#REG_SZ value:&set_export_path expand:false
            
            -- btn_folder.text = set_export_path

            mcolor = dotnetclass "System.drawing.color" 
            maxBackColor = colorMan.getColor #background
            BackColor = mColor.FromArgb (maxBackColor[1] * 255.0f) (maxBackColor[2] * 255.0f) (maxBackColor[3] * 255.0f)            
            font = dotNetObject "System.Drawing.Font" "微软雅黑" 12
            
            Btn_ForeColor = (dotnetclass "System.drawing.color").Red
            btn_export.BackColor = BackColor
            
            lb_0.font = lb_1.font = font
            lb_0.foreColor = lb_1.foreColor = Btn_ForeColor
            lb_0.backColor = lb_1.backColor = BackColor

            btn_export.font = dotNetObject "System.Drawing.Font" "Impact" 25
            btn_export.ForeColor = Btn_ForeColor
            btn_export.FlatStyle = (dotnetclass "System.Windows.Forms.FlatStyle").Flat
            btn_export.BackColor = BackColor            
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
            str = "编译时间：" + _data
            -- messageBox "此版本编译于2022-02-11\n此版本限制：仅支持Vray英文版，不支持汉化版本\n其它材质不会导出"
            str += "\n版本更新内容：\n"
            str += "【新增】支持Corona标准材质\n"
            str += "【新增】支持标准材质\n"
            str += "【新增】使用新的命名方式处理重名的材质和物体\n"
            str += "【修复】导出模型部分破面问题\n"
            str += "【修复】VRay代理物体添加修改器后无法正常导出\n"
            str += "【修改】暂时禁用导出环境设置\n"
            messageBox str
        )

        on btn_folder pressed do (
            folder = getSavepath()
            if folder != undefined do (
                et_folder.text = folder

                -- 写入注册表        
                setRegistryKey "SOFTWARE\\REDHALO" "Export" folder
            )
        )

        on btn_export click e do (

            AssetHashCode = #()
            AssetPath = #()

            pb.value = 5
            
            disableSceneRedraw()
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

            -- 重定义贴图路径
            RetargetPath()
            -- 场景清理
            DuplicateObjectNam()
            
            ResetGroupPivot()
            ClearUserProp()
            ShapeToPoly()
            DeleteEmptyPoly()
            
            pb.value = 30

            if export_proxy do ExportProxy xmlDoc ProxyListElement

            ExportSetting xmlDoc SettingElement
            ExportLight xmlDoc LightListElement
            ExportCamera xmlDoc CameraListElement
            ExportEnvironment xmlDoc EnvironmentElement
            ExportObject xmlDoc ObjectListElement
            
            -- 强制更新场景材质
            saveNodes #() (export_path + "RHEMP.max")
           
            -- 删除代理物体上的修改器，避免导出时出现错误
            for i in objects do (
                removeProxyModifier i
            )

            -- 删除相机和灯光
            cams = Cameras as Array
            delete cams
            alllight = Lights as Array
            delete alllight
            
            pb.value = 50

            -- 清理材质管理器
            CleanMeditSlot()

            -- 处理不支持的材质
            for cls in material.classes do (	
                for m in getClassInstances cls do (
                    CleanupMaterial m
                )
            )

            pb.value = 70
            --RHPUI.msg.text = "当前进度 >>>>  【导出材质配置文件】"
            SceneMaterial = GetSceneMaterials()
            
            for i in SceneMaterial do (
                cls = classof i

                /*  ===== VRAY MATERIAL ===== */
                -- VRay 2 sides material
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
                if cls == VRayOverrideMtl2 do (
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

                    -- 判断是不是玻璃
                    clr = getProperty i "Diffuse"
                    ref = getProperty i "refraction"
                    refr = getProperty i "Refraction"

                    if clr.v < 10 and ref.v > 230 and refr.v > 230 do (
                        setProperty i "Diffuse" White
                    )

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

                            -- Opacity Displacement
                            if (prop == "texmap_opacity_multiplier") or (prop == "texmap_displacement_multiplier") or (prop == "texmap_bump_multiplier") do (
                                if texture > 100 then texture = 100
                                value = texture / 100.0
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
                
                /* ===== STANDARD MATERIAL ===== */
                -- Standard Material
                if cls == StandardMaterial do (
                    SingleMtl = xmlDoc.createElement "SingleMtl"
                    MaterialList.appendChild singleMtl

                    SingleMtl.setAttribute "name" i.name
                    SingleMtl.setAttribute "useRoughness" "false"

                    
                    -- Diffuse <Diffuse Color Texmap />
                    Diffuse = xmlDoc.createElement "Diffuse"
                    SingleMtl.appendChild Diffuse
                    
                    -- StandardMaterial ShaderType
                    -- 0- Anisotropic / 1- Blinn (default type)  /  2- Metal  /  3- Multi-Layer
                    -- 4- Oren-Nayar-Blinn / 5- Phong / 6- Strauss / 7-Translucent
                    shaderType = getProperty i "shaderType"

                    Diffuse.setAttribute "Color" ((getProperty i "Diffuse") as string)

                    diffuse_tex = getProperty i "DiffuseMap"
                    if diffuse_tex == undefined then (
                        Diffuse.setAttribute "Texmap" "undefined"
                    )else(
                        Diffuse.setAttribute "Texmap" (diffuse_tex as string)
                        CreateElement xmlDoc Diffuse diffuse_tex
                    )
                    
                    -- Metallic <Metallic Amount Texmap />
                    Metallic = xmlDoc.createElement "Metallic"
                    SingleMtl.appendChild Metallic
                    Metallic.setAttribute "Amount" "0.0"
                    Metallic.setAttribute "Texmap" "undefined"
                    
                    -- Specular <Reflection Amount= Texmap />
                    Reflection = xmlDoc.createElement "Reflection"
                    SingleMtl.appendChild Reflection
                    refl_clr = getProperty i "Specular"
                    specularLevel = (getProperty i "specularLevel") / 999.0
                    Reflection.setAttribute "Amount" ((refl_clr.v / 255.0 * specularLevel) as string)

                    refl_tex = getProperty i "SpecularMap"
                    if refl_tex == undefined then (
                        Reflection.setAttribute "Texmap" "undefined"
                    )else(
                        Reflection.setAttribute "Texmap" (refl_tex as string)
                        CreateElement xmlDoc Reflection refl_tex                        
                    )

                    -- Roungness <Roughness Amount Texmap />
                    Roungness = xmlDoc.createElement "Roughness"
                    SingleMtl.appendChild Roungness

                    glossiness = 1 - (getProperty i "glossiness")/100.0
                    Roungness.setAttribute "Amount" (glossiness as string)
                    Roungness.setAttribute "Texmap" "undefined"

                    -- Anisotropic <Anisotropic Amount Texmap />
                    Anisotropic = xmlDoc.createElement "Anisotropic"
                    SingleMtl.appendChild Anisotropic
                    anisotropy = 0 --(getProperty i "anisotropy") / 100
                    Anisotropic.setAttribute "Amount" (anisotropy as string)
                    Anisotropic.setAttribute "Texmap" "undefined"

                    -- AnisotropicRotation <AnisotropicRotation Amount Texmap />
                    AnisotropicRotation = xmlDoc.createElement "AnisotropicRotation"
                    SingleMtl.appendChild AnisotropicRotation

                    orientation = 0 --( mod (getProperty i "orientation") 180.0 ) / 180.0
                    AnisotropicRotation.setAttribute "Amount" (orientation as string)
                    AnisotropicRotation.setAttribute "Texmap" "undefined"
                    
                    -- Sheen <Sheen Amount Texmap />
                    Sheen = xmlDoc.createElement "Sheen"
                    SingleMtl.appendChild Sheen
                    Sheen.setAttribute "Amount" "0.0"
                    Sheen.setAttribute "Texmap" "undefined"

                    -- Coat <Coat Amount Texmap />
                    Coat = xmlDoc.createElement "Coat"
                    SingleMtl.appendChild Coat
                    Coat.setAttribute "Amount" "0.0"
                    Coat.setAttribute "Texmap" "undefined"

                    -- CoatRoughness <CoatRoughness Amount Texmap />
                    CoatRoughness = xmlDoc.createElement "CoatRoughness"
                    SingleMtl.appendChild CoatRoughness
                    CoatRoughness.setAttribute "Amount" "0.0"
                    CoatRoughness.setAttribute "Texmap" "undefined"

                    -- IOR <IOR Amount Texmap />
                    IOR = xmlDoc.createElement "IOR"
                    SingleMtl.appendChild IOR
                    IOR.setAttribute "Amount" "1.6"
                    IOR.setAttribute "Texmap" "undefined"

                    -- Refraction <Refraction Amount Texmap />
                    Refraction = xmlDoc.createElement "Refraction"
                    SingleMtl.appendChild Refraction
                    Refraction.setAttribute "Amount" "0.0"
                    Refraction.setAttribute "Texmap" "undefined"

                    -- RefractRoundness <RefractRoundness Amount Texmap />
                    RefractRoughness = xmlDoc.createElement "RefractRoughness"
                    SingleMtl.appendChild RefractRoughness
                    RefractRoughness.setAttribute "Amount" "0.0"
                    RefractRoughness.setAttribute "Texmap" "undefined"

                    -- Emission <Emission Color Texmap/>
                    -- EmissionStrength <EmissionStrength Amount Texmap/>
                    Emission = xmlDoc.createElement "Emission"
                    SingleMtl.appendChild Emission

                    EmissionStrength = xmlDoc.createElement "EmissionStrength"
                    SingleMtl.appendChild EmissionStrength

                    emission_amount = getProperty i "selfIllumAmount"
                    if emission_amount > 100 then (
                        emission_amount = 1
                    )else(
                        emission_amount = emission_amount / 100.0
                    )

                    emission_clr = getProperty i "SELFILLUMCOLOR"
                    emission_on = getProperty i "useSelfIllumColor"

                    if emission_on then (
                        Emission.setAttribute "Color" (emission_clr as string)
                        EmissionStrength.setAttribute "Amount" "1.0"
                    )else(
                        Emission.setAttribute "Color" "(color 255 255 255)"
                        EmissionStrength.setAttribute "Amount" (emission_amount as string)
                    )
                    
                    EmissionStrength.setAttribute "Texmap" "100.0"
                    
                    emission_map = getProperty i "selfillumMap"
                    if emission_map == undefined then (
                        Emission.setAttribute "Texmap" "undefined"
                    )else(
                        Emission.setAttribute "Texmap" (emission_map as string)
                        CreateElement xmlDoc Emission emission_map
                    )

                    
                    -- Opacity <Opacity Amount Texmap />
                    Opacity = xmlDoc.createElement "Opacity"
                    SingleMtl.appendChild Opacity

                    op_amount = getProperty i "Opacity"
                    Opacity.setAttribute "Amount" ((op_amount / 100.0) as string)

                    op_tex = getProperty i "OpacityMap"
                    if op_tex == undefined then (
                        Opacity.setAttribute "Texmap" "undefined"
                    )else(
                        Opacity.setAttribute "Texmap" (op_tex as string)
                        CreateElement xmlDoc Opacity op_tex
                    )

                    -- Normal/Bump <Bump Amount Texmap />
                    Normal = xmlDoc.createElement "Bump"
                    SingleMtl.appendChild Normal

                    Normal.setAttribute "Amount" "30.0"

                    normal_tex = getProperty i "bumpMap"
                    if normal_tex == undefined then (
                        Normal.setAttribute "Texmap" "undefined"
                    )else(
                        Normal.setAttribute "Texmap" (normal_tex as string)
                        CreateElement xmlDoc Normal normal_tex
                    )

                    -- Translucent <Translucent Texmap />
                    -- <Translucent Texmap="undefined" />
                    Translucent = xmlDoc.createElement "Translucent"
                    SingleMtl.appendChild Translucent
                    Translucent.setAttribute "Texmap" "undefined"

                    -- Displacement <Displacement Amount Texmap />
                    -- <Displacement Amount="100.0" Texmap="undefined" />
                    Displacement = xmlDoc.createElement "Displacement"
                    SingleMtl.appendChild Displacement
                    Displacement.setAttribute "Amount" "100.0"
                    Displacement.setAttribute "Texmap" "undefined"

                )

                -- DoubleSide Material
                if cls == DoubleSided do (
                    SideMtl = xmlDoc.CreateElement "DoubleSideMtl"
                    MaterialList.appendChild SideMtl

                    SideMtl.setAttribute "name" i.name
                    /*
                    #material1
                    #material2
                    #map1Enabled
                    #map2Enabled
                    #translucency
                    */

                    -- Font Material
                    FontMtl = getProperty i "material1"
                    SideMtl.setAttribute "frontmtl" (FontMtl as string)
                    CreateElement xmlDoc sideMtl FontMtl

                    -- Back Material
                    BackMtl = getProperty i "material2"
                    SideMtl.setAttribute "backmtl" (BackMtl as string)
                    CreateElement xmlDoc SideMtl BackMtl
                    
                    -- Translucency
                    trans = ( getProperty i "translucency" ) / 100
                    clr = White.v * trans
                    SideMtl.setAttribute "translucency" (clr as string)

                )

                /* ===== CORONA MATERIAL ===== */
                -- CoronaMtl / CoronaLegacyMtl
                if cls == CoronaMtl do (  
                    SingleMtl = xmlDoc.createElement "SingleMtl"
                    MaterialList.appendChild singleMtl

                    SingleMtl.setAttribute "name" i.name
                    SingleMtl.setAttribute "useRoughness" "false"

                    /*
                    处理IOR，当IOR大于5的时候，判定为金属材质
                    */
                    DiffuseColor = getProperty i "colorDiffuse"
                    DiffuseLevel = getProperty i "levelDiffuse"
                    Diffuse_Color_Final = DiffuseColor * [DiffuseLevel*255, DiffuseLevel*255, DiffuseLevel*255]

                    ReflectIOR = getProperty i "fresnelIor"
                    RefractIOR = getProperty i "IOR"

                    ReflectLevel = getProperty i "levelReflect"
                    ReflectColor = getProperty i "colorReflect"
                    Reflect_Final = ReflectColor * [ReflectLevel*255, ReflectLevel*255, ReflectLevel*255]

                    RefractLevel = getProperty i "levelRefract"
                    RefractColor = getProperty i "colorRefract"
                    Refract_Final = RefractColor * [RefractLevel*255, RefractLevel*255, RefractLevel*255]

                    IOR = 1.52
                    MetallicValue = 0

                    if ReflectIOR > 5 then (
                        MetallicValue = 1.0
                        if ReflectColor.s > 5 then (
                            setProperty i "colorDiffuse" ReflectColor
                            setProperty i "colorReflect" (color 255 255 255)
                        )
                        IOR = 1.52
                    ) else (
                        MetallicValue = 0
                        IOR = RefractIOR
                    )
                    
                    -- 此参数可能是玻璃
                    if Diffuse_Color_Final.s < 5 and Reflect_Final.s < 8 and Reflect_Final.v > 250 and Refract_Final.s < 8 and Refract_Final.v > 250 then (
                        setProperty i "colorDiffuse" White
                    )                    

                    -- Diffuse <Diffuse Color Texmap />
                    Diffuse = xmlDoc.createElement "Diffuse"
                    SingleMtl.appendChild Diffuse
                    
                    DiffuseColor = getProperty i "ColorDiffuse"
                    DiffuseLevel = getProperty i "LevelDiffuse"
                    DiffuseColor_Final = DiffuseColor * [DiffuseLevel*255, DiffuseLevel*255, DiffuseLevel*255]
                    Diffuse.setAttribute "Color" (DiffuseColor_Final as string)
                    
                    DiffuseTexmap = getProperty i "texmapDiffuse"
                    if (getProperty i "texmapOnDiffuse") and (DiffuseTexmap != undefined) then (
                        Diffuse.setAttribute "Texmap" (DiffuseTexmap as string)
                        CreateElement xmlDoc Diffuse DiffuseTexmap
                    ) else (
                        setProperty i "texmapDiffuse" undefined
                        Diffuse.setAttribute "Texmap" "undefined"
                    )

                    -- Metallic <Metallic Amount Texmap />
                    Metallic = xmlDoc.createElement "Metallic"
                    SingleMtl.appendChild Metallic
                    Metallic.setAttribute "Amount" (MetallicValue as string)
                    Metallic.setAttribute "Texmap" "undefined"
                    
                    -- Specular <Reflection Amount= Texmap />
                    Reflection = xmlDoc.createElement "Reflection"
                    SingleMtl.appendChild Reflection

                    ReflectValue = ReflectColor.v / 255.0 * ReflectLevel
                    Reflection.setAttribute "Amount" (ReflectValue as string)

                    ReflectTexmap = getProperty i "texmapReflect"
                    if (getProperty i "texmapOnReflect") and (ReflectTexmap != undefined) then (
                        Reflection.setAttribute "Texmap" (ReflectTexmap as string)
                        CreateElement xmlDoc Reflection ReflectTexmap
                    ) else (
                        setProperty i "texmapReflect" undefined
                        Reflection.setAttribute "Texmap" "undefined"
                    )
                    
                    -- Roungness <Roughness Amount Texmap />
                    Roungness = xmlDoc.createElement "Roughness"
                    SingleMtl.appendChild Roungness
                    
                    glossiness = getProperty i "reflectGlossiness"
                    Roungness.setAttribute "Amount" (glossiness as string)
                    
                    RoungnessTexmap = getProperty i "texmapReflectGlossiness"
                    if (getProperty i "texmapOnReflectGlossiness") and (RoungnessTexmap != undefined) then (
                        Roungness.setAttribute "Texmap" (RoungnessTexmap as string)
                        CreateElement xmlDoc Roungness RoungnessTexmap
                    ) else (
                        setProperty i "texmapReflectGlossiness" undefined
                        Roungness.setAttribute "Texmap" "undefined"
                    )

                    -- Anisotropic <Anisotropic Amount Texmap />
                    Anisotropic = xmlDoc.createElement "Anisotropic"
                    SingleMtl.appendChild Anisotropic

                    anisotropy = abs (getProperty i "anisotropy")
                    Anisotropic.setAttribute "Amount" (anisotropy as string)

                    AnisotropicTexmap = getProperty i "texmapReflectAnisotropy"
                    if (getProperty i "texmapOnAnisotropy") and (AnisotropicTexmap != undefined) then (
                        Anisotropic.setAttribute "Texmap" (AnisotropicTexmap as string)
                        CreateElement xmlDoc Anisotropic AnisotropicTexmap
                    ) else (
                        setProperty i "texmapReflectAnisotropy" undefined
                        Anisotropic.setAttribute "Texmap" "undefined"
                    )

                    -- AnisotropicRotation <AnisotropicRotation Amount Texmap />
                    AnisotropicRotation = xmlDoc.createElement "AnisotropicRotation"
                    SingleMtl.appendChild AnisotropicRotation

                    orientation = (getProperty i "anisotropyRotation") / 360.0
                    AnisotropicRotation.setAttribute "Amount" (orientation as string)
                    
                    AnisoTexmap = getProperty i "texmapReflectAnisotropyRotation"
                    if (getProperty i "texmapOnAnisotropyRotation") and (AnisoTexmap != undefined) then (
                        AnisotropicRotation.setAttribute "Texmap" (AnisoTexmap as string)
                        CreateElement xmlDoc AnisotropicRotation AnsioTexmap
                    ) else (
                        setProperty i "texmapReflectAnisotropyRotation" undefined
                        AnisotropicRotation.setAttribute "Texmap" "undefined"
                    )
                    
                    -- Sheen <Sheen Amount Texmap />
                    Sheen = xmlDoc.createElement "Sheen"
                    SingleMtl.appendChild Sheen
                    Sheen.setAttribute "Amount" "0.0"
                    Sheen.setAttribute "Texmap" "undefined"

                    -- Coat <Coat Amount Texmap />
                    Coat = xmlDoc.createElement "Coat"
                    SingleMtl.appendChild Coat
                    Coat.setAttribute "Amount" "0.0"
                    Coat.setAttribute "Texmap" "undefined"

                    -- CoatRoughness <CoatRoughness Amount Texmap />
                    CoatRoughness = xmlDoc.createElement "CoatRoughness"
                    SingleMtl.appendChild CoatRoughness
                    CoatRoughness.setAttribute "Amount" "0.0"
                    CoatRoughness.setAttribute "Texmap" "undefined"

                    -- IOR <IOR Amount Texmap />
                    IORNODE = xmlDoc.createElement "IOR"
                    SingleMtl.appendChild IORNODE
                    IORNODE.setAttribute "Amount" (IOR as string)
                    
                    IORTexmap = getProperty i "texmapIor"
                    if (getProperty i "texmapOnIor") and ( IORTexmap != undefined) then (
                        IORNODE.setAttribute "Texmap" (IORTexmap as string)
                        CreateElement xmlDoc IORNODE IORTexmap
                    ) else (
                        setProperty i "texmapIor" undefined
                        IORNODE.setAttribute "Texmap" "undefined"
                    )

                    -- Refraction <Refraction Amount Texmap />
                    Refraction = xmlDoc.createElement "Refraction"
                    SingleMtl.appendChild Refraction
                    
                    RefractColor = getProperty i "colorrefract"
                    RefractLevel = getProperty i "levelrefract"
                    RefractValue = RefractColor.v / 255.0 * RefractLevel
                    Refraction.setAttribute "Amount" (RefractValue as string)

                    RefractTexmap = getProperty i "texmapRefract"
                    if (getProperty i "texmapOnRefract") and ( RefractTexmap != undefined) then (
                        Refraction.setAttribute "Texmap" (RefractTexmap as string)
                        CreateElement xmlDoc Refraction RefractTexmap
                    ) else (
                        setProperty i "texmapRefract" undefined
                        Refraction.setAttribute "Texmap" "undefined"
                    )

                    -- RefractRoundness <RefractRoundness Amount Texmap />
                    RefractRoughness = xmlDoc.createElement "RefractRoughness"
                    SingleMtl.appendChild RefractRoughness
                    refractGlossiness = getProperty i "refractGlossiness"
                    RefractRoughness.setAttribute "Amount" (refractGlossiness as string)

                    RefractRoughnessTexmap = getProperty i "texmapRefractGlossiness"
                    if (getProperty i "texmapOnRefractGlossiness") and (RefractRoughnessTexmap != undefined) then (
                        RefractRoughness.setAttribute "Texmap" (RefractRoughnessTexmap as string)
                        CreateElement xmlDoc RefractRoughness RefractRoughnessTexmap
                    ) else (
                        setProperty i "texmapRefractGlossiness" undefined
                        RefractRoughness.setAttribute "Texmap" "undefined"
                    )

                    -- Emission <Emission Color Texmap/>
                    Emission = xmlDoc.createElement "Emission"
                    SingleMtl.appendChild Emission

                    COLORSELFILLUM = getProperty i "COLORSELFILLUM"
                    Emission.setAttribute "Color" (COLORSELFILLUM as string)

                    EmissionTexmap = getProperty i "texmapSelfIllum"
                    if (getProperty i "texmapOnSelfIllum") and (EmissionTexmap != undefined) then (
                        Emission.setAttribute "Texmap" (EmissionTexmap as string)
                        CreateElement xmlDoc Emission EmissionTexmap
                    ) else (
                        setProperty i "texmapSelfIllum" undefined
                        Emission.setAttribute "Texmap" "undefined"
                    )
                    
                    -- EmissionStrength <EmissionStrength Amount Texmap/>
                    EmissionStrength = xmlDoc.createElement "EmissionStrength"
                    SingleMtl.appendChild EmissionStrength
                    
                    LEVELSELFILLUM = getProperty i "LEVELSELFILLUM"
                    EmissionStrength.setAttribute "Amount" (LEVELSELFILLUM as string)
                    EmissionStrength.setAttribute "Texmap" "undefined"
                    
                    -- Opacity <Opacity Amount Texmap />
                    Opacity = xmlDoc.createElement "Opacity"
                    SingleMtl.appendChild Opacity

                    op_amount = (getProperty i "levelOpacity")
                    Opacity.setAttribute "Amount" (op_amount as string)

                    op_texmap = getProperty i "texmapOpacity"
                    if (getProperty i "texmapOnOpacity") and (op_texmap != undefined) then (
                        Opacity.setAttribute "Texmap" (op_texmap as string)
                        CreateElement xmlDoc Opacity op_texmap
                    ) else (
                        setProperty i "texmapOpacity" undefined
                        Opacity.setAttribute "Texmap" "undefined"
                    )

                    -- Normal/Bump <Bump Amount Texmap />
                    Normal = xmlDoc.createElement "Bump"
                    SingleMtl.appendChild Normal

                    NormalValue = (getProperty i "mapamountBump") / 10.0
                    Normal.setAttribute "Amount" (NormalValue as string)
                    
                    BumpTexmap = getProperty i "texmapBump"
                    if (getProperty i "texmapOnBump") and (BumpTexmap != undefined) then (
                        Normal.setAttribute "Texmap" (BumpTexmap as string)
                        CreateElement xmlDoc Normal BumpTexmap
                    ) else (
                        setProperty i "texmapBump" undefined
                        Normal.setAttribute "Texmap" "undefined"
                    )

                    -- Translucent <Translucent Texmap />
                    -- <Translucent Texmap="undefined" />
                    Translucent = xmlDoc.createElement "Translucent"
                    SingleMtl.appendChild Translucent

                    TransColor = getProperty i "colorTranslucency"
                    TransLevel = getProperty i "levelTranslucency"
                    Clr = TransColor * [TransLevel*255, TransLevel*255, TransLevel*255]
                    Translucent.setAttribute "Color" (Clr as string)

                    Trans_Texmap = getProperty i "texmapTranslucency"
                    if (getProperty i "texmapOnTranslucency") and (Trans_Texmap != undefined) then (
                        Translucent.setAttribute "Texmap" (Trans_Texmap as string)
                        CreateElement xmlDoc Translucent Trans_Texmaps
                    ) else (
                        setProperty i "texmapTranslucency" undefined
                        Translucent.setAttribute "Texmap" "undefined"
                    )

                    -- Displacement <Displacement Amount Texmap />
                    -- <Displacement Amount="100.0" Texmap="undefined" />
                    Displacement = xmlDoc.createElement "Displacement"
                    SingleMtl.appendChild Displacement

                    Displacement.setAttribute "Amount" "100.0"

                    DisplaceMap = getProperty i "texmapDisplacement"
                    if (getProperty i "texmapondisplacement") and ( DisplaceMap != undefined) then (
                        Displacement.setAttribute "Texmap" (DisplaceMap as string)
                        CreateElement xmlDoc Displacement DisplaceMap
                    ) else (
                        setProperty i "texmapdisplace" undefined
                        Displacement.setAttribute "Texmap" "undefined"
                    )
                )

                -- CoronaPhysicalMtl [Corona 7+]
                if cls == CoronaPhysicalMtl do (

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
                        LightMtl.setAttribute att_name (att as string)
                    )

                    LightMap = xmlDoc.CreateElement "Lightmap"
                    LightMtl.appendChild Lightmap
                    tex = getProperty i "texmap"
                    print tex
                    if tex != undefined do (
                        CreateElement xmlDoc LightMap tex
                    )

                    OpacityMap = xmlDoc.CreateElement "Opacitymap"
                    LightMtl.appendChild OpacityMap
                    tex = getProperty i "opacitytexmap"
                    CreateElement xmlDoc OpacityMap tex
                )
            )
            
            pb.value = 100
            --RHPUI.msg.text = "当前进度 >>>>  【导出模型】"
            
            -- if et_folder.text != "" do export_path = et_folder.text
            local save_err = ""
            try(xmlDoc.Save (export_path + xmlname))catch(
                save_err = "无法保存配置文件,导出失败"
            )
            try(xmlDoc.Save ("D:\\xml_Temp.xml"))catch() --测试文件，方便查看
            xmlDoc = undefined

            try(DestroyDialog RHPUI)catch()
            if save_err == "" then (
                --------FBX EXPORT-----
                pluginManager.loadClass FBXEXPORTER
                --Geometry------------------------------------------------------------------------

                FBXExporterSetParam "SmoothingGroups" false
                FBXExporterSetParam "NormalsPerPoly" false
                FBXExporterSetParam "TangentSpaceExport" false
                FBXExporterSetParam "SmoothMeshExport" true
                FBXExporterSetParam "Preserveinstances" true
                FBXExporterSetParam "SelectionSetExport" false
                FBXExporterSetParam "Triangulate" false
                --Animation------------------------------------------------------------------------
                FBXExporterSetParam "Animation" true
                FBXExporterSetParam "Removesinglekeys" true
                --Cameras------------------------------------------------------------------------
                FBXExporterSetParam "Cameras" false
                --Lights------------------------------------------------------------------------
                FBXExporterSetParam "Lights" false
                --Embed Media--------------------------------------------------------------------
                FBXExporterSetParam "EmbedTextures" false
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
                    24000: ( FBXExporterSetParam "FileVersion" "FBX202000" )
                    -- 3dsmax 2021
                    23000: ( FBXExporterSetParam "FileVersion" "FBX202000" )
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
                    -- other vesions
                    default: ( FBXExporterSetParam "FileVersion" "FBX201600" )	
                )
                -----------------------------------------------------------------------------------	
                fbx = export_path + fbxname

                if export_mode == 1 then (
                    exportFile fbx #noPrompt selectedOnly:true	usage:FBXEXP
                )else(
                    exportFile fbx #noPrompt selectedOnly:false	usage:FBXEXP
                )

                enableSceneRedraw()
				completeRedraw()
                -- clearListener()
                messageBox "导出成功，请在Blender中用插件导入" title:"Red Halo M2B"
            )else(
                messageBox save_err title:"Red Halo M2B"
            )

        )
    )
    createDialog M2B width:400
)