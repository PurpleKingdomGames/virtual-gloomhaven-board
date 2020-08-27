using GloomhavenBoardHelper.Models;
using Microsoft.AspNetCore.SignalR;
using System.Threading.Tasks;

namespace GloomhavenBoardHelper.Handlers
{
    public class SignalRHandler : Hub {
        public async Task SendGameState(string joinCode, string gameState) =>
            await Clients.Group(joinCode).SendAsync("ReceiveGameState", gameState);

        public async Task CreateRoom() {
            string roomCode = GameRoom.GenerateCode();

            await Clients.Client(Context.ConnectionId).SendAsync("RoomCreated", roomCode);
            await JoinRoom(roomCode);
        }

        public async Task LeaveRoom(string roomCode) =>
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, roomCode);

        public async Task JoinRoom(string roomCode) {
            await Groups.AddToGroupAsync(Context.ConnectionId, roomCode);
            await Clients.GroupExcept(roomCode, Context.ConnectionId).SendAsync("PushGameState");
        }
    }
}