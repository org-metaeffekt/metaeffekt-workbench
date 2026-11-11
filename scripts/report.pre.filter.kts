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

/*
 This script loads the inventory referenced by "input.inventory.dir" (despite its name, a single inventory file),
 keeps only the assets marked as primary and writes the result to the file referenced by "output.inventory.dir".
 */

val inputFileProperty = params["input.inventory.dir"]
val outputFileProperty = params["output.inventory.dir"]

logProperties()
processInventory()

/**
 * Main script entrypoint. Reads the input inventory, filters its asset metadata and writes the filtered inventory
 * to the output file.
 */
fun processInventory() {
    val inputFilePath = requireNonBlank(inputFileProperty, "input.inventory.dir") ?: return
    val outputFilePath = requireNonBlank(outputFileProperty, "output.inventory.dir") ?: return

    val inventory = loadInventory("input.inventory.dir")

    val assets = inventory.assetMetaData
    val primaryAssets: List<AssetMetaData> = assets.filter { it.isPrimary() }
    inventory.assetMetaData = primaryAssets

    writeInventory(inventory, "output.inventory.dir", createParents = true)

    println("INFO: Wrote '$outputFilePath' with ${primaryAssets.size} of ${assets.size} assets kept as primary.")
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
    println("INFO: inputFileProperty = $inputFileProperty")
    println("INFO: outputFileProperty = $outputFileProperty")
}
