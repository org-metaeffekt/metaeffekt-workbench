@file:DependsOn("com.fasterxml.jackson.module:jackson-module-kotlin:2.17.0")
@file:DependsOn("com.fasterxml.jackson.dataformat:jackson-dataformat-yaml:2.17.0")

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory
import com.fasterxml.jackson.module.kotlin.registerKotlinModule
import org.jetbrains.kotlin.com.google.common.io.Files
import java.io.File


val propertiesFile = args[0]
val workspaceDir = args[1]
val curlArguments = args.drop(2)
    .flatMap { argument -> argument.split(Regex("\\s+")).filter { it.isNotBlank() } }

fun main() {
    val mapper = ObjectMapper(YAMLFactory()).registerKotlinModule()
    val configFile = File(propertiesFile)
    val root: RootProperties = mapper.readValue(configFile, RootProperties::class.java)
    fetchAssets(root.projectProperties)
}

fun fetchAssets(projectProperties: ProjectProperties) {
    var targetFile: File = File("")
    var url: String? = null

    for (asset in projectProperties.assets) {
        if (!asset.urlResolver?.url.isNullOrBlank()) {
            targetFile = craftTargetFile(projectProperties.project, asset)
            url = asset.urlResolver.url
        } else if (!asset.urlResolver?.urlPattern.isNullOrBlank()) {
            targetFile = craftTargetFile(projectProperties.project, asset)
            url = craftAssetUrl(asset)
        } else {
            throw IllegalArgumentException("Missing required information in properties file.")
        }
        Files.createParentDirs(targetFile);
        downloadAsset(url, targetFile)
    }
}

fun downloadAsset(url: String, targetFile: File) {
    println("Downloading $url -> ${targetFile.absolutePath}")
    val command = mutableListOf<String>("curl", "-L", "-f", "-o", targetFile.path)
    command.addAll(curlArguments)
    command.add(url)

    val process = ProcessBuilder(command).inheritIO().start()
    val exitCode = process.waitFor()
    if (exitCode != 0) {
        throw RuntimeException("Asset download failed with code $exitCode")
    }
}

fun craftAssetUrl(asset: Asset): String {
    val pattern = asset.urlResolver?.urlPattern ?: throw IllegalArgumentException("urlPattern is null")

    val placeholders = mapOf(
        "name" to asset.name,
        "version" to asset.version
    )

    val regex = Regex("""\$\{([^}]+)}""")

    val result = regex.replace(pattern) { matchResult ->
        val key = matchResult.groupValues[1]
        val value = placeholders[key]

        if (value.isNullOrBlank()) {
            throw IllegalStateException("Missing or blank value for placeholder: \${$key}")
        }
        value
    }

    return result
}

fun craftTargetFile(project: Project, asset: Asset): File {
    val sb = StringBuilder(workspaceDir).append("/")

    val projectPart = buildNameVersionString(project.name, project.version)
    sb.appendIfExists(projectPart)

    if (sb.isNotEmpty() && !sb.endsWith("/")) sb.append("/")
    sb.append("00_fetched/")

    val assetPart = buildNameVersionString(asset.name, asset.version)
    sb.appendIfExists(assetPart)

    if (!assetPart.isNullOrBlank()) {
        sb.append("/")
        sb.append(assetPart).append(".zip")
    } else {
        sb.append("unknown_asset.zip")
    }

    return File(sb.toString())
}

fun buildNameVersionString(name: String?, version: String?): String? {
    val n = if (name.isNullOrBlank()) null else name
    val v = if (version.isNullOrBlank()) null else version

    return when {
        n != null && v != null -> "$n-$v"
        n != null -> n
        v != null -> v
        else -> null
    }
}

main()

fun StringBuilder.appendIfExists(value: String?): StringBuilder {
    if (!value.isNullOrBlank()) append(value)
    return this
}

data class ProjectProperties(
    val project: Project,
    val assets: List<Asset>,
)

data class RootProperties(
    val projectProperties: ProjectProperties
)

data class Project(
    val name: String?,
    val version: String?
)

data class Asset(
    val name: String?,
    val version: String?,
    val urlResolver: UrlResolver?,
    val mavenResolver: MavenResolver?
)

data class UrlResolver(
    val url: String?,
    val urlPattern: String?
)

data class MavenResolver(
    val artifactId: String?,
    val artifactGroup: String?,
    val artifactVersion: String?,
)
