using VirtualGloomhavenBoard.Models;
using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace VirtualGloomhavenBoard.Handlers
{
    public class SignalRHandler : Hub {
        public async Task SendGameState(string roomCode, object gameState) {
            if (!string.IsNullOrEmpty(roomCode))
                await Clients.Group(roomCode).SendAsync("ReceiveGameState", gameState);
        }

        public async Task CreateRoom() {
            string roomCode = GameRoom.GenerateCode();

            await Clients.Client(Context.ConnectionId).SendAsync("RoomCreated", roomCode);
            await JoinRoom(roomCode);
        }

        public async Task LeaveRoom(string roomCode) {
            if (!string.IsNullOrEmpty(roomCode))
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, roomCode);
        }

        public async Task JoinRoom(string roomCode) {
            if (!GameRoom.ValidateCode(roomCode)) {
                await Clients.Client(Context.ConnectionId).SendAsync("InvalidRoomCode");
            } else {
                await Groups.AddToGroupAsync(Context.ConnectionId, roomCode);
                await Clients.GroupExcept(roomCode, Context.ConnectionId).SendAsync("PushGameState");
            }
        }
    }
}