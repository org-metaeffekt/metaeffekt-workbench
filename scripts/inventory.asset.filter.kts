import org.metaeffekt.core.inventory.processor.model.AssetMetaData

val inventory = loadInventory("input.inventory.file")

val assetToKeep = params.getValue("param.asset.id")

val assetsToKeep = inventory.assetMetaData.filter {
    (it.get(AssetMetaData.Attribute.ASSET_ID) ?: it.get(AssetMetaData.Attribute.NAME)) == assetToKeep
}
val assetsToRemove = inventory.assetMetaData.filter {
    (it.get(AssetMetaData.Attribute.ASSET_ID) ?: it.get(AssetMetaData.Attribute.NAME)) != assetToKeep
}

inventory.assetMetaData = assetsToKeep

val assetAttributesToRemove = assetsToRemove.mapNotNull {
    it.get(AssetMetaData.Attribute.ASSET_ID) ?: it.get(AssetMetaData.Attribute.NAME)
}

for (artifact in inventory.artifacts) {
    for (assetAttributeToRemove in assetAttributesToRemove) {
        artifact.set(assetAttributeToRemove, null)
    }
}

writeInventory(inventory, "output.inventory.file")
