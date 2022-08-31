fn GetSceneMaterials = (
	AllSceneMaterialsName = #()
	AllSceneMaterials = #()
	for cls in material.classes do (
		for i in getClassInstances cls do (
			for m in refs.dependents i do (		
				if superclassof m == GeometryClass do (
					if appendIfUnique AllSceneMaterialsName i.name then (
						append AllSceneMaterials i
					) else (
						i.name = i.name + "-" + (timeStamp() as string)
						append AllSceneMaterials i
					)
				)
			)
		)
	)
	return AllSceneMaterials
)

for i in AllSceneMaterials do (
	print i
)

scenefilename = maxfilepath + maxFileName

fileassets = getMAXFileAssetMetadata scenefilename


for i = 1 to AssetManager.GetNumAssets() do
(
	local AUIO = AssetManager.GetAssetByIndex i
	local bm_id = AUIO.GetAssetId()
	local bm_filename = AUIO.getfilename()
	local bm_realPath = mapPaths.getFullFilePath(filenameFromPath bm_filename)
	
	for i in fileassets do (
		if bm_id == i.assetid do (
			fileassets.filename = bm_realPath
		)
	)	
)

setMAXFileAssetMetadata scenefilename fileassets
gc()