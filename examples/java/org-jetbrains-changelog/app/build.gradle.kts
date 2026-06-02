plugins {
    java
    id("org.jetbrains.changelog") version "2.5.0"
}

group = "com.example"
version = "1.0.0"

changelog {
    version.set(project.version.toString())
    path.set("${project.projectDir}/CHANGELOG.md")
    header.set(provider { "[${project.version}]" })
    groups.set(listOf("Added", "Changed", "Fixed"))
}

tasks.jar {
    manifest {
        attributes["Main-Class"] = "tipcalc.Main"
    }
}
