package vgb

object GameSync:

  enum Msg:
      case ClientDisconnected
      case ClientConnected
      case UpdateReceived(data: String)
      case Disconnected
      case Connected
      case Reconnecting
      case JoinRoom(code: String)
      case RoomCodeReceived(code: String)
      case RoomCodeInvalid

