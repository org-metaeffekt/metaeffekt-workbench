import org.metaeffekt.core.inventory.processor.model.Inventory
import org.metaeffekt.core.inventory.processor.reader.InventoryReader
import org.metaeffekt.core.inventory.processor.writer.InventoryWriter
import java.io.File

/*
 This script should not need to be adjusted except for adding new filter presets in the getFilterPairsForPreset() method
 below. One example on how to set up a new filter has been provided in the method body.
 */

val inputDirProperty = System.getProperty("input.inventory.dir")
val outputDirProperty = System.getProperty("output.inventory.dir")
val filterPresetProperty = System.getProperty("param.filter.preset")
val assetNameProperty = System.getProperty("param.asset.name")

logProperties()
processInventories()

/**
 * Main script entrypoint, which defines the flow of how the script processes the given input directories and how they
 * are written to the output directory.
 *
 * In this case, all input inventories are split based on which artifacts have the same type and written to the output directory.
 * The initial input inventories are also written to the output directory.
 */
fun processInventories() {
    val inputDirPath = requireNonBlank(inputDirProperty, "input.inventory.dir") ?: return
    val outputDirPath = requireNonBlank(outputDirProperty, "output.inventory.dir") ?: return
    val assetName = assetNameProperty?.takeIf { it.isNotBlank() } ?: "asset"

    val outputDir = File(outputDirPath)
    if (!outputDir.exists() && !outputDir.mkdirs()) {
        println("ERROR: Could not create output directory at $outputDirPath")
        return
    }

    val inventories = getInputInventories(inputDirPath)
    if (inventories.isEmpty()) {
        println("WARNING: No inventories found in $inputDirPath")
        return
    }

    val filterPairs = getFilterPairsForPreset(filterPresetProperty)
    if (filterPairs.isEmpty()) {
        println("WARNING: No filter pairs found for preset '${filterPresetProperty ?: ""}'. Only writing base inventories.")
    }

    val inventoryWriter = InventoryWriter()

    for (inventory in inventories) {
        val originalArtifacts = inventory.getArtifacts().toList()

        for ((key, value) in filterPairs) {
            val filteredList = originalArtifacts.filter { artifact ->
                artifact.get(key)?.contains(value, ignoreCase = true) == true
            }

            if (filteredList.isNotEmpty()) {
                inventory.setArtifacts(filteredList)
                val fileName = "$assetName-$value.xlsx"
                val outputFile = File(outputDir, fileName)

                println(outputFile.absolutePath)
                inventoryWriter.writeInventory(inventory, outputFile)
            }
        }

        inventory.setArtifacts(originalArtifacts)
        inventoryWriter.writeInventory(inventory, File(outputDir, "$assetName.xlsx"))
    }
}

/**
 * Gathers only inventories present in the "inputDirPath" input directory.
 *
 * @return a list of inventory objects for further processing
 */
fun getInputInventories(inputDirPath: String): List<Inventory> {
    val inputDir = File(inputDirPath)
    if (!inputDir.exists() || !inputDir.isDirectory) {
        println("ERROR: Input directory does not exist or is not a directory: $inputDirPath")
        return emptyList()
    }

    val inventoryReader = InventoryReader()
    val inventories = mutableListOf<Inventory>()

    val filteredFiles = inputDir.listFiles()
        ?.filter { file ->
            file.isFile && (file.extension.equals("xls", ignoreCase = true) ||
                file.extension.equals("xlsx", ignoreCase = true))
        }
        ?: emptyList()

    for (file in filteredFiles) {
        try {
            val data = inventoryReader.readInventory(file)
            inventories.add(data)
        } catch (exception: Exception) {
            println("ERROR: Failed to read inventory '${file.name}': ${exception.message}")
        }
    }

    return inventories
}

/**
 * Contains a variety of lists which are accessible via pre-defined presets.
 * These lists contain artifact "attribute -> value" pairs.
 *
 * @return A list of artifact attribute -> value string pairs
 */
fun getFilterPairsForPreset(preset: String?): List<Pair<String, String>> {
    return when (preset) {
        "multi-asset" -> listOf(
            Pair("Type", "driver"),
            Pair("Type", "os"),
            Pair("Type", "os-package"),
            Pair("Type", "application")
        )
        // Add new filter preset here
        else -> emptyList()
    }
}

fun requireNonBlank(value: String?, propertyName: String): String? {
    if (value.isNullOrBlank()) {
        println("ERROR: Missing required system property '$propertyName'.")
        return null
    }

    return value
}

fun logProperties() {
    println("INFO: Running group.kts scripts with the following properties:")
    println("INFO: inputDirProperty = $inputDirProperty")
    println("INFO: outputDirProperty = $outputDirProperty")
    println("INFO: filterPresetProperty = $filterPresetProperty")
    println("INFO: assetNameProperty = $assetNameProperty")
}
