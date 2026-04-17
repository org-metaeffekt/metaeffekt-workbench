@file:DependsOn("com.fasterxml.jackson.module:jackson-module-kotlin:2.17.0")
@file:DependsOn("com.fasterxml.jackson.dataformat:jackson-dataformat-yaml:2.17.0")

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory
import com.fasterxml.jackson.module.kotlin.registerKotlinModule
import java.io.File


val propertiesFile = args[0]
val envFile = args[1]

fun main() {
    val mapper = ObjectMapper(YAMLFactory()).registerKotlinModule()
    val configFile = File(propertiesFile)
    val root: RootProperties = mapper.readValue(configFile, RootProperties::class.java)
    writeEnvFile(root.projectProperties)
}

fun writeEnvFile(projectProperties: ProjectProperties) {
    val project = projectProperties.project
    val asset = projectProperties.assets[0]

    val projectName = project.name ?: ""
    val projectVersion = project.version ?: ""
    val projectId = buildNameVersionString(projectName, projectVersion)

    val assetName = asset.name ?: ""
    val assetVersion = asset.version ?: ""
    val assetId = buildNameVersionString(assetName, assetVersion)
    
    val lines = mutableListOf<String>()

    lines.add("DEFAULT_PARAM_PROJECT_NAME=$projectName")
    lines.add("DEFAULT_PARAM_PROJECT_VERSION=$projectVersion")
    lines.add("DEFAULT_PARAM_PROJECT_ID=$projectId")
    lines.add("DEFAULT_PARAM_ASSET_NAME=$assetName")
    lines.add("DEFAULT_PARAM_ASSET_VERSION=$assetVersion")
    lines.add("DEFAULT_PARAM_ASSET_ID=$assetId")

    println(lines)
    val target = File(envFile)
    target.parentFile?.mkdirs()
    target.writeText(lines.joinToString("\n", postfix = "\n"))
}

fun buildNameVersionString(name: String, version: String): String {
    val n = if (name.isBlank()) null else name
    val v = if (version.isBlank()) null else version

    return when {
        n != null && v != null -> "$n-$v"
        n != null -> n
        v != null -> v
        else -> ""
    }
}

main()

data class RootProperties(
    val projectProperties: ProjectProperties
)

data class ProjectProperties(
    val project: Project,
    val assets: List<Asset>,
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
