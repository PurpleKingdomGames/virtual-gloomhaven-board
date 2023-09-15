package vgb.game.models

enum TileRotation:
  case Default, Horizontal, Vertical, VerticalReverse, DiagonalLeft,
    DiagonalRight, DiagonalLeftReverse, DiagonalRightReverse

  def toByte(): Byte =
    this match {
      case Default              => 0
      case DiagonalLeft         => 1
      case Vertical             => 0
      case DiagonalRight        => 2
      case Horizontal           => 3
      case DiagonalLeftReverse  => 4
      case VerticalReverse      => 3
      case DiagonalRightReverse => 5
    }

  def nextRotation(hasVertical: Boolean) =
    this match {
      case Default              => DiagonalLeft
      case DiagonalLeft         => if hasVertical then Vertical else DiagonalRight
      case Vertical             => DiagonalRight
      case DiagonalRight        => Horizontal
      case Horizontal           => DiagonalLeftReverse
      case DiagonalLeftReverse  => if hasVertical then VerticalReverse else DiagonalRightReverse
      case VerticalReverse      => DiagonalRightReverse
      case DiagonalRightReverse => Default
    }

  override def toString() =
    this match {
      case Default              => "default"
      case DiagonalLeft         => "diagonal-left"
      case Vertical             => "vertical"
      case DiagonalRight        => "diagonal-right"
      case Horizontal           => "horizontal"
      case DiagonalLeftReverse  => "diagonal-left-reverse"
      case VerticalReverse      => "vertical-reverse"
      case DiagonalRightReverse => "diagonal-right-reverse"
    }

object TileRotation:
  def fromString(dir: String) =
    dir match {
      case "diagonal-left"          => DiagonalLeft
      case "vertical"               => Vertical
      case "diagonal-right"         => DiagonalRight
      case "horizontal"             => Horizontal
      case "diagonal-left-reverse"  => DiagonalLeftReverse
      case "vertical-reverse"       => VerticalReverse
      case "diagonal-right-reverse" => DiagonalRightReverse
      case _                        => Default
    }

  def fromByte(i: Byte) =
    TileRotation.values
      // We can't discern vertical just from the byte, so don't try
      .filter(t => t != Vertical && t != VerticalReverse)
      .find(t => t.toByte() == i)
      .getOrElse(Default)
