package vgb.common

import indigo.shared.collections.Batch

final case class DragDropSection(name: String, items: Batch[DragDropItem])
