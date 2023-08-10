package vgb.common

import indigo.Point
import indigo.shared.collections.Batch

import org.scalajs.dom

/** A message from the VGB app
  */
trait GloomhavenMsg

/** General messages that can be used across many scenes
  */
enum GeneralMsgType extends GloomhavenMsg:
  case ShowContextMenu(position: Point, menu: Menu)
  case CloseContextMenu

enum CreatorMsgType extends GloomhavenMsg:
  case ChangeMonsterLevel(pos: Point, m: MonsterType, playerNum: Byte, monsterLevel: MonsterLevel)
  case RemoveMonster(pos: Point, m: MonsterType)
  case RotateOverlay(id: Int, o: BoardOverlayType)
  case RemoveOverlay(id: Int, o: BoardOverlayType)
  case RotateRoom(r: RoomType)
  case RemoveRoom(r: RoomType)
  case CreateNewScenario
  case ShowImportDialog
  case ImportFileSelected(file: dom.File)
  case ChangeScenarioTitle(title: String)
  case UpdateDragMenu(sections: Batch[DragDropSection])
  case SetSelectedDragSection(sectionName: String)
  case NewDragStart(dragItem: RoomType | BoardOverlayType | MonsterType)
  case DragEnd
  case SelectFile
  case ExportFile
  case ExportFileString(title: String, json: String)
