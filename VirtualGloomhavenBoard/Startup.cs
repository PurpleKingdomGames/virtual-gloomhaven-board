using VirtualGloomhavenBoard.Handlers;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.AspNetCore.Http;
using System;
using Microsoft.Net.Http.Headers;

namespace VirtualGloomhavenBoard
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public static void ConfigureServices(IServiceCollection services)
        {
            services.AddSignalR();
            services.AddResponseCompression();
            services.AddResponseCaching();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app)
        {
            string? configHost = Configuration.GetValue<string>("HostUrl");
            if (configHost?.ToLower().StartsWith("https://") == true)
            {
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
                app.UseHttpsRedirection();
            }

            FileExtensionContentTypeProvider contentTypeProvider = new();
            contentTypeProvider.Mappings[".scss"] = "text/x-scss";

            StaticFileOptions fileOptions = new();
            fileOptions.ContentTypeProvider = contentTypeProvider;
            fileOptions.OnPrepareResponse = _ =>
            {
                string path = _.Context.Request.Path;
                if (path.EndsWith(".css") || path.EndsWith(".js"))
                {

                    _.Context.Response.GetTypedHeaders().CacheControl =
                        new CacheControlHeaderValue()
                        {
                            Public = true,
                            NoCache = true
                        }
                    ;
                }
                else
                {
                    _.Context.Response.GetTypedHeaders().CacheControl =
                        new CacheControlHeaderValue()
                        {
                            Public = true,
                            MaxAge = TimeSpan.FromDays(10)
                        }
                    ;
                }

                _.Context.Response.Headers[HeaderNames.Vary] =
                    new string[] { "Accept-Encoding" };

            };

            app.UseResponseCompression();
            app.UseDefaultFiles();
            app.UseStaticFiles(fileOptions);

            app.UseRouting();
            app.UseEndpoints(endpoints =>
            {
                endpoints.MapHub<SignalRHandler>("/ws");
            });
        }
    }
}
