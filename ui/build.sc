import $ivy.`com.goyeau::mill-scalafix::0.2.11`
import com.goyeau.mill.scalafix.ScalafixModule
import $ivy.`com.lihaoyi::mill-contrib-bloop:$MILL_VERSION`
import mill._
import mill.scalalib._
import mill.scalajslib._
import mill.scalajslib.api._
import scalafmt._

import $ivy.`io.github.davidgregory084::mill-tpolecat::0.3.2`
import io.github.davidgregory084.TpolecatModule

object ui extends ScalaJSModule with TpolecatModule with ScalafixModule with ScalafmtModule {
  def scalaVersion   = "3.2.2"
  def scalaJSVersion = "1.13.0"
  val tyrianVersion = "0.6.2" 

  def buildSite() =
    T.command {
      T {
        compile()
        fastLinkJS()
      }
    }

  def ivyDeps =
    Agg(
      ivy"io.indigoengine::tyrian-io::$tyrianVersion"
    )

  override def moduleKind = T(mill.scalajslib.api.ModuleKind.CommonJSModule)

  def scalafixIvyDeps = Agg(ivy"com.github.liancheng::organize-imports:0.6.0")

  object test extends Tests {
    def ivyDeps = Agg(
      ivy"org.scalameta::munit::0.7.29"
    )

    def testFramework = "munit.Framework"

    override def moduleKind = T(mill.scalajslib.api.ModuleKind.CommonJSModule)

  }

}
