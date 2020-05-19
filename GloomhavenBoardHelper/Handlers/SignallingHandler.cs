using System.Net.WebSockets;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using System.Threading;
using System;
using Microsoft.Extensions.Caching.Distributed;
using System.Text;
using System.Linq;

namespace GloomhavenBoardHelper.Handlers
{
    public class SignallingHandler
    {
        private const string ESCAPE_SEQUENCE = "\r\n";

        private const string PONG_RESPONSE = "PONG";
        private const string PING_COMMAND = "PING";
        private const string OFFER_COMMAND = "OFFER";
        private const string ANSWER_COMMAND  = "ANSWER";

        public static async Task Init(HttpContext context, WebSocket webSocket, int bufferSize, int timeout, IDistributedCache cache) {
            byte[] buffer = new byte[bufferSize];
            StringBuilder receivedText = new StringBuilder();
            CancellationToken timeOutToken = new CancellationTokenSource(timeout * 1000 * 2).Token;
            WebSocketReceiveResult result = null;

            try
            {
                result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), timeOutToken);
                while (!result.CloseStatus.HasValue)
                {
                    receivedText.Append(Encoding.UTF8.GetString(buffer.Take(result.Count).ToArray()));
                    string currentText = receivedText.ToString();

                    if (currentText.Contains(ESCAPE_SEQUENCE))
                    {
                        receivedText.Clear();
                        receivedText.Append(await ProcessCommand(webSocket, currentText));
                    }
                        result = await webSocket.ReceiveAsync(new ArraySegment<byte>(buffer), timeOutToken);

                }
            }
            catch (OperationCanceledException)
            {
                // Do nothing, this is a time out
            }
            finally
            {
                await Close(webSocket, result);
            }
        }

        private static async Task<string> ProcessCommand(WebSocket webSocket, string strCommand)
        {
            string[] commands = strCommand.Split(ESCAPE_SEQUENCE);
            for (int i = 0; i < commands.Length; i++) {
                string[] commandParts = commands[i].Split(" ");
                switch(commandParts[0])
                {
                    case PING_COMMAND:
                        await Pong(webSocket);
                        break;
                    case OFFER_COMMAND:
                        await Offer(webSocket, commandParts.Skip(1).ToArray());
                        break;
                }
            }

            return commands[commands.Length - 1];
        }

        private static async Task Pong(WebSocket webSocket)
        {
            ArraySegment<byte> bytesToSend = Encoding.UTF8.GetBytes(PONG_RESPONSE + ESCAPE_SEQUENCE);

            await webSocket.SendAsync(bytesToSend, WebSocketMessageType.Text, true, CancellationToken.None);
        }

        private static async Task Offer(WebSocket webSocket, string[] args)
        {
            await Pong(webSocket);
        }

        private static async Task Close(WebSocket webSocket, WebSocketReceiveResult result = null)
        {
            await webSocket.CloseAsync(result?.CloseStatus.Value ?? WebSocketCloseStatus.Empty, result?.CloseStatusDescription, CancellationToken.None);
        }
    }
}