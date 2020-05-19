using System;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using System.Net.WebSockets;
using GloomhavenBoardHelper.Handlers;
using Microsoft.Extensions.Caching.Distributed;

namespace GloomhavenBoardHelper
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddDistributedMemoryCache();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (!env.IsDevelopment())
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();

            app.UseHttpsRedirection();
            app.UseStaticFiles();
            app.UseDefaultFiles();

            int keepAlive = Configuration.GetValue<int>("KeepAlive");
            int bufferSize = Configuration.GetValue<int>("BufferSizeKb") * 1024;

            app.UseWebSockets(new WebSocketOptions {
                KeepAliveInterval = TimeSpan.FromSeconds(keepAlive),
                ReceiveBufferSize = bufferSize
            });

            app.Use(async (context, next) => {
                if (context.Request.Path == "/ws")
                    if (context.WebSockets.IsWebSocketRequest)
                    {
                        WebSocket webSocket = await context.WebSockets.AcceptWebSocketAsync();
                        await SignallingHandler.Init(context, webSocket, bufferSize, keepAlive, context.RequestServices.GetRequiredService<IDistributedCache>());
                    }
                    else
                        context.Response.StatusCode = 400;
                else
                    await next();
            });
        }
    }
}
