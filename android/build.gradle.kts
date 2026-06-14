allprojects {
    repositories {
      // maven { url = uri("https://pub-azs.ir/api/mavens/") }
        maven { url = uri("https://maven.myket.ir") }
        maven { url = uri("https://archive.ito.gov.ir/gradle/maven_central") }
  //     google()
       mavenCentral()
       maven { url = uri("https://maven.aliyun.com/repository/jcenter") }
       maven { url = uri("https://maven.aliyun.com/repository/google") }
       maven { url = uri("https://maven.aliyun.com/repository/central") }
       

    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
