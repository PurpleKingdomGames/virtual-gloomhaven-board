package vgb.common
import vgb.common.BaseGame

enum Expansion(base: BaseGame):
  override def toString(): String =
    this match {
      case None(base)       => base.toString()
      case Solo(base)       => base.toString() + " Solo Scenarios"
      case ForgottenCircles => base.toString() + " + FC"
    }
  case None(base: BaseGame) extends Expansion(base)
  case Solo(base: BaseGame) extends Expansion(base)
  case ForgottenCircles     extends Expansion(BaseGame.Gloomhaven)
