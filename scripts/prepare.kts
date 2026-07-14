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
import com.metaeffekt.artifact.analysis.flow.scripting.InventoryScriptingLanguage

/*
 This script should not need to be adjusted except for adding new filter presets in the getFilterPairsForPreset() method
 below. One example on how to set up a new filter has been provided in the method body.
 */

val inputFilePath = System.getProperty("input.inventory.dir")
val outputFilePath = System.getProperty("output.inventory.dir")

logProperties()
processInventories()

/**
 * Main script entrypoint, which defines the flow of how the script processes the given input directories and how they
 * are written to the output directory.
 *
 * In this case, input inventories are gathered from different stages in the workspace and copies to their respective
 * target subdirectories in the 07_grouped stage. This is a pre-processing step, necessary for dashboard and report creation.
 */
fun processInventories() {
    val inputFilePath = requireNonBlank(inputFilePath, "input.inventory.dir") ?: return
    val outputFilePath = requireNonBlank(outputFilePath, "output.inventory.dir") ?: return

    val inventory = loadInventory("input.inventory.dir")
    val ISL = InventoryScriptingLanguage(inventory);

    // remove detected descriptors
    ISL.selectArtifacts().idEndsWith(".idx").remove();
    ISL.selectArtifacts().idEndsWith(".txt").remove();
    ISL.selectArtifacts().idEndsWith(".MF").remove();
    ISL.selectArtifacts().idEndsWith(".xml").remove();
    ISL.selectArtifacts().idEndsWith(".pom").remove();
    ISL.selectArtifacts().idEndsWith(".class").remove();
    ISL.selectArtifacts().idEndsWith(".sql").remove();
    ISL.selectArtifacts().idEndsWith(".md").remove();
    ISL.selectArtifacts().idEndsWith(".jks").remove();
    ISL.selectArtifacts().idEndsWith(".yaml").remove();
    ISL.selectArtifacts().idEquals("env.rc").remove();
    ISL.selectArtifacts().idEquals("java.nio.file.spi.FileSystemProvider").remove();

    ISL.selectArtifacts().idEquals("ae-inventory-index-deployer-HEAD-SNAPSHOT").remove();
    ISL.selectArtifacts().idEquals("inventory-index-deployment-HEAD-SNAPSHOT.zip").remove();

    ISL.selectArtifacts().pathInAssetContains("[inventory-index-deployment-HEAD-SNAPSHOT.zip]/01_setup/sql/").remove();
    ISL.selectArtifacts().pathInAssetContains("[inventory-index-deployment-HEAD-SNAPSHOT.zip]/03_test/").remove();

    println(ISL.getReport());

    writeInventory(inventory, "output.inventory.dir", createParents = true)
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
    println("INFO: inputFilePath = $inputFilePath")
    println("INFO: outputFilePath = $outputFilePath")
}
