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