/*
 * Copyright 2009-2026 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import org.metaeffekt.core.inventory.processor.model.AssetMetaData
import org.metaeffekt.core.inventory.processor.reader.InventoryReader
import org.metaeffekt.core.inventory.processor.writer.InventoryWriter
import java.io.File

/*
 This script loads every inventory from the "input.inventory.dir" directory, keeps only the assets marked as
 primary and writes each resulting inventory under its original name to the "output.inventory.dir" directory.
 */

val inputDirProperty = params["input.inventory.dir"]
val outputDirProperty = params["output.inventory.dir"]

logProperties()
processInventories()

/**
 * Main script entrypoint. Reads all inventories in the input directory, filters their asset metadata and writes
 * the filtered inventories to the output directory.
 */
fun processInventories() {
    val inputDirPath = requireNonBlank(inputDirProperty, "input.inventory.dir") ?: return
    val outputDirPath = requireNonBlank(outputDirProperty, "output.inventory.dir") ?: return

    val inputDir = File(inputDirPath)
    if (!inputDir.exists() || !inputDir.isDirectory) {
        println("ERROR: Input directory does not exist or is not a directory: $inputDirPath")
        return
    }

    val outputDir = File(outputDirPath)
    if (!outputDir.exists() && !outputDir.mkdirs()) {
        println("ERROR: Could not create output directory at $outputDirPath")
        return
    }

    val inventoryFiles = inputDir.listFiles()
        ?.filter { it.isFile && isInventoryFile(it) }
        ?.sortedBy { it.name }
        ?: emptyList()

    if (inventoryFiles.isEmpty()) {
        println("WARNING: No inventories found in $inputDirPath")
        return
    }

    val inventoryReader = InventoryReader()
    val inventoryWriter = InventoryWriter()

    for (inputFile in inventoryFiles) {
        val inventory = inventoryReader.readInventory(inputFile)

        val assets = inventory.assetMetaData
        val primaryAssets: List<AssetMetaData> = assets.filter { it.isPrimary() }
        inventory.assetMetaData = primaryAssets

        // Keep the original file name so the result can be matched to its input.
        val outputFile = File(outputDir, inputFile.name)
        inventoryWriter.writeInventory(inventory, outputFile)

        println("INFO: Wrote '${outputFile.path}' with ${primaryAssets.size} of ${assets.size} assets kept as primary.")
    }
}

/**
 * @return whether the given file has an extension supported by the InventoryReader
 */
fun isInventoryFile(file: File): Boolean =
    InventoryReader.getSupportedFileExtensions().any { extension ->
        file.name.endsWith(extension, ignoreCase = true)
    }

fun requireNonBlank(value: String?, propertyName: String): String? {
    if (value.isNullOrBlank()) {
        println("ERROR: Missing required parameter '$propertyName'.")
        return null
    }

    return value
}

fun logProperties() {
    println("INFO: Running report.pre.filter.kts with the following parameters:")
    println("INFO: inputDirProperty = $inputDirProperty")
    println("INFO: outputDirProperty = $outputDirProperty")
}
