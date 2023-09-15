package vgb

import BoardOverlayType.Door
import DoorSubType.DarkFog

object SpecialRules:

  def scenario101DoorUpdate(state: GameState): GameState =
    (removeJ1bbFog andThen removeJ1bFog)(state)

  def removeJ1bbFog(state: GameState): GameState =
    val shouldRemove =
      state.visibleRooms.exists(_ == MapTileRef.J1ba) &&
        state.visibleRooms.exists(_ == MapTileRef.J1bb)

    if shouldRemove then state.copy(overlays = removeFog(List((9, 10), (8, 9), (8, 8)), state.overlays))
    else state

  def removeJ1bFog(state: GameState): GameState =
    val shouldRemove =
      state.visibleRooms.exists(_ == MapTileRef.J1ba) &&
        state.visibleRooms.exists(_ == MapTileRef.J1b)

    if shouldRemove then state.copy(overlays = removeFog(List((4, 11), (5, 10), (4, 9)), state.overlays))
    else state

  def removeFog(cells: List[(Int, Int)], overlays: List[BoardOverlay]): List[BoardOverlay] =
    overlays.flatMap { o =>
      if cells.exists(c => o.cells.exists(_ == c)) then
        o.ref match
          case Door(DarkFog, _) =>
            None

          case _ =>
            Option(o)
      else Option(o)
    }
