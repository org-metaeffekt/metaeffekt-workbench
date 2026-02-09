import java.io.File

/*
 This script should not need to be adjusted except for adding new filter presets in the getFilterPairsForPreset() method
 below. One example on how to set up a new filter has been provided in the method body.
 */

val inputDirProperty = System.getProperty("input.inventory.dir")
val outputDirProperty = System.getProperty("output.inventory.dir")
val assetNameProperty = System.getProperty("param.asset.name")

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
    val inputDirPath = requireNonBlank(inputDirProperty, "input.inventory.dir") ?: return
    val outputDirPath = requireNonBlank(outputDirProperty, "output.inventory.dir") ?: return
    val assetName = assetNameProperty?.takeIf { it.isNotBlank() }

    val outputDir = File(outputDirPath)
    if (!outputDir.exists() && !outputDir.mkdirs()) {
        println("ERROR: Could not create output directory at $outputDirPath")
        return
    }

    val resolvedSource = File("$inputDirPath/04_resolved/$assetName")
    val aggregatedSource = File("$inputDirPath/03_aggregated/$assetName")
    val resolvedFallbackSource = if (hasFiles(resolvedSource)) resolvedSource else aggregatedSource

    if (!hasFiles(resolvedFallbackSource)) {
        println("WARNING: No inventories found in 04_resolved or 03_aggregated for asset '${assetName ?: ""}'.")
    }

    copyFilesToTargetLocation(
        resolvedFallbackSource,
        File("$outputDirPath/$assetName/custom-annex")
    )
    copyFilesToTargetLocation(
        resolvedFallbackSource,
        File("$outputDirPath/$assetName/software-distribution-annex")
    )

    copyFilesToTargetLocation(
        File("$inputDirPath/05_scanned/$assetName"),
        File("$outputDirPath/$assetName/initial-license-documentation")
    )
    copyFilesToTargetLocation(
        File("$inputDirPath/05_scanned/$assetName"),
        File("$outputDirPath/$assetName/license-documentation")
    )

    copyFilesToTargetLocation(
        File("$inputDirPath/06_advised/$assetName"),
        File("$outputDirPath/$assetName/vulnerability-report")
    )
    copyFilesToTargetLocation(
        File("$inputDirPath/06_advised/$assetName"),
        File("$outputDirPath/$assetName/vulnerability-summary-report")
    )
    copyFilesToTargetLocation(
        File("$inputDirPath/06_advised/$assetName"),
        File("$outputDirPath/$assetName/cert-report")
    )
    copyFilesToTargetLocation(
        File("$inputDirPath/06_advised/$assetName"),
        File("$outputDirPath/$assetName/dashboard")
    )
}

/**
 * Copies the selected source files from different directories to their respective sub directories in the grouped dir.
 *
 * @param sourceDirectory the inventory source directory
 * @param targetDirectory the grouped directory in which to copy all inventories found at the sourceLocation
 */
fun copyFilesToTargetLocation(sourceDirectory: File, targetDirectory: File) {
    if (!sourceDirectory.exists() || !sourceDirectory.isDirectory) {
        println("WARNING: Source directory missing: ${sourceDirectory.path}")
        return
    }

    if (!targetDirectory.exists() && !targetDirectory.mkdirs()) {
        println("ERROR: Could not create target directory at ${targetDirectory.path}")
        return
    }

    val files = sourceDirectory.listFiles()?.filter { it.isFile } ?: emptyList()
    if (files.isEmpty()) {
        println("WARNING: No files to copy from ${sourceDirectory.path}")
        return
    }

    for (file in files) {
        try {
            file.copyTo(File(targetDirectory, file.name), true)
        } catch (exception: Exception) {
            println("ERROR: Failed to copy '${file.name}' to ${targetDirectory.path}: ${exception.message}")
        }
    }
}


fun hasFiles(directory: File): Boolean {
    return directory.exists() && directory.isDirectory && directory.listFiles()?.any { it.isFile } == true
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
    println("INFO: assetNameProperty = $assetNameProperty")
}
