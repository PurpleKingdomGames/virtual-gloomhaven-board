using System.Net.WebSockets;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using System.Threading;
using System;
using System.Text;
using System.Linq;
using StackExchange.Redis;

namespace GloomhavenBoardHelper.Handlers
{
    public class SignallingHandler
    {
        private const string ESCAPE_SEQUENCE = "\r\n";
        private const string PONG_RESPONSE = "PONG";
        private const string PING_COMMAND = "PING";
        private const string OFFER_COMMAND = "OFFER";
        private const string ANSWER_COMMAND  = "ANSWER";
        private const string UPDATE_COMMAND  = "UPDATE";

        public static async Task Init(HttpContext context, WebSocket webSocket, int bufferSize, int timeout, ISubscriber notifier) {
            byte[] buffer = new byte[bufferSize];
            StringBuilder receivedText = new StringBuilder();
            int timeoutMillis = timeout * 1000 * 2;
            CancellationToken timeOutToken = new CancellationTokenSource(timeoutMillis).Token;
            WebSocketReceiveResult result = null;
            string category = context.Connection.RemoteIpAddress.ToString();

            await notifier.SubscribeAsync(category, async (_, v) => await SendResponse(webSocket, v));

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
                        receivedText.Append(await ProcessCommand(webSocket, currentText, category, notifier));
                    }

                    timeOutToken = new CancellationTokenSource(timeoutMillis).Token;
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

        private static async Task<string> ProcessCommand(WebSocket webSocket, string strCommand, string category, ISubscriber notifier)
        {
            string[] commands = strCommand.Split(ESCAPE_SEQUENCE);
            for (int i = 0; i < commands.Length; i++) {
                string[] commandParts = commands[i].Split(" ", 3);
                switch(commandParts[0])
                {
                    case PING_COMMAND:
                        await Pong(webSocket, category, notifier);
                        break;
                    case OFFER_COMMAND:
                        await Offer(webSocket, category, notifier, commandParts.Skip(1).ToArray());
                        break;
                    case ANSWER_COMMAND:
                        await Answer(webSocket, category, notifier, commandParts.Skip(1).ToArray());
                        break;
                    case UPDATE_COMMAND:
                        await Update(webSocket, category, notifier, commandParts.Skip(1).ToArray());
                        break;
                }
            }

            return commands[commands.Length - 1];
        }

        private static async Task Pong(WebSocket webSocket, string category, ISubscriber notifier)
        {
            await notifier.PublishAsync(category, PONG_RESPONSE);
        }

        private static async Task Offer(WebSocket webSocket, string category, ISubscriber notifier, string[] args)
        {
            if (args.Length != 2)
                return;

            await notifier.PublishAsync(args[0], $"{OFFER_COMMAND} {category} {args[1]}");
        }

        private static async Task Answer(WebSocket webSocket, string category, ISubscriber notifier, string[] args)
        {
            if (args.Length != 2)
                return;

            await notifier.PublishAsync(args[0], $"{ANSWER_COMMAND} {category} {args[1]}");
        }

        private static async Task Update(WebSocket webSocket, string category, ISubscriber notifier, string[] args)
        {
            if (args.Length != 2)
                return;

            await notifier.PublishAsync(args[0], $"{UPDATE_COMMAND} {category} {args[1]}");
        }

        private static async Task SendResponse(WebSocket webSocket, string response)
        {
            ArraySegment<byte> bytesToSend = Encoding.UTF8.GetBytes(response + ESCAPE_SEQUENCE);

            if (webSocket.State == WebSocketState.Open)
                await webSocket.SendAsync(bytesToSend, WebSocketMessageType.Text, true, CancellationToken.None);
        }

        private static async Task Close(WebSocket webSocket, WebSocketReceiveResult result = null)
        {
            if (new[] { WebSocketState.CloseReceived, WebSocketState.CloseSent, WebSocketState.Open }.Contains(webSocket.State))
                await webSocket.CloseAsync(result?.CloseStatus ?? WebSocketCloseStatus.Empty, result?.CloseStatusDescription, CancellationToken.None);
        }
    }
}