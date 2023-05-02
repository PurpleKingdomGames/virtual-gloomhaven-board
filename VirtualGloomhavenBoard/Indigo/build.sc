import $ivy.`com.lihaoyi::mill-contrib-bloop:$MILL_VERSION`
import mill._
import mill.scalalib._
import mill.scalajslib._
import mill.scalajslib.api._
import $file.gamedata.gameData

import $ivy.`io.github.davidgregory084::mill-tpolecat::0.3.2`
import io.github.davidgregory084.TpolecatModule

object `vgb-common` extends VgbModule

object `vgb-game` extends VgbModule {
  override def moduleDeps = Seq(`vgb-common`)

  // generatedSources is a list of paths to source files.
  // It is called on compile, so by hooking in our function
  // our code is re-generated on compilation.
  override def generatedSources: T[Seq[PathRef]] = T {
    // Set a working directory inside the `out` dir
    val wd = os.pwd / "out" / "gamedata"
    // Make sure it exists
    os.makeDir.all(wd)

    gameData.CodeGen
      .generate()
      .map(d =>
        d match {
          case (file, data) =>
            // Write to the file
            os.write.over(
              wd / s"""${file.capitalize}.scala""",
              s"""/* This file is auto-generated. Please do not modify it manually */
              |${data}""".stripMargin.trim
            )
        }
      )

    // Call out code gen function and concat the paths onto
    // the standard path list.
    Seq(PathRef(wd)) ++ super.generatedSources()
  }
}

object `vgb-ui` extends VgbModule {
  override def moduleDeps = Seq(`vgb-common`, `vgb-game`)

  def build() =
    T.command {
      T {
        compile()
        fastOpt()
      }
    }
}

trait VgbModule extends ScalaJSModule with TpolecatModule {
  def scalaVersion   = "3.2.2"
  def scalaJSVersion = "1.13.1"

  val indigoVersion = "0.14.0"
  val tyrianVersion = "0.6.1"

  def ivyDeps =
    Agg(
      ivy"io.indigoengine::tyrian-io::$tyrianVersion",
      ivy"io.indigoengine::tyrian-indigo-bridge::$tyrianVersion",
      ivy"io.indigoengine::indigo-json-circe::$indigoVersion",
      ivy"io.indigoengine::indigo::$indigoVersion",
      ivy"io.indigoengine::indigo-extras::$indigoVersion",
      ivy"org.scala-js:scalajs-java-securerandom_sjs1_2.13:1.0.0"
    )

  override def moduleKind = T(mill.scalajslib.api.ModuleKind.CommonJSModule)

  object test extends Tests with TestModule.Munit {

    def ivyDeps = Agg(
      ivy"org.scalameta::munit::1.0.0-M7"
    )
  }
}
