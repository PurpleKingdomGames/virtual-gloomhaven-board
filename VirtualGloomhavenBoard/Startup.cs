using VirtualGloomhavenBoard.Handlers;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.FileProviders;
using Microsoft.AspNetCore.StaticFiles;
using Microsoft.AspNetCore.Http;
using System;
using System.IO;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.Net.Http.Headers;
using Microsoft.AspNetCore.Rewrite;

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
            services
                .AddSignalR()
                .AddMessagePackProtocol()
            ;
            services.AddResponseCompression();
            services.AddResponseCaching();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app)
        {
            string? configHost = Configuration.GetValue<string>("HostUrl");
            string assetPath = Path.Combine(
                Path.GetDirectoryName(
                    Assembly.GetExecutingAssembly().Location
                ) ?? string.Empty,
                "assets"
            );

            Regex versionRegex = new("([0-9]+.[0-9]+.[0-9]+)");
            string version = versionRegex
                .Match(
                    File.ReadAllText(
                        Path.Combine(
                            Path.GetDirectoryName(
                                Assembly.GetExecutingAssembly().Location
                            ) ?? string.Empty,
                            "Elm/src",
                            "Version.elm"
                        )
                    )
                )
                .Value
            ;
            UpdateHtmlWithVersion(new[] { "index.html", "creator.html" }, version, assetPath);

            if (configHost?.ToLower().StartsWith("https://") == true)
            {
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
                app.UseHttpsRedirection();
            }

            FileExtensionContentTypeProvider contentTypeProvider = new();
            contentTypeProvider.Mappings[".scss"] = "text/x-scss";

            StaticFileOptions fileOptions = new();
            fileOptions.FileProvider = new PhysicalFileProvider(assetPath);
            fileOptions.ContentTypeProvider = contentTypeProvider;
            fileOptions.OnPrepareResponse = _ =>
            {
                string path = _.Context.Request.Path;
                if (path.EndsWith(".css") || path.EndsWith(".js") || path.EndsWith(".html"))
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

            app.UseRewriter(new RewriteOptions()
                .AddRewrite("^Creator", "/creator.html", true)
            );

            DefaultFilesOptions defaultFilesOptions = new DefaultFilesOptions();
            defaultFilesOptions.DefaultFileNames.Clear();
            defaultFilesOptions.DefaultFileNames.Add("index.html");
            defaultFilesOptions.FileProvider = new PhysicalFileProvider(assetPath);

            app.UseDefaultFiles(defaultFilesOptions);
            app.UseStaticFiles(fileOptions);

            app.UseRouting();
            app.UseEndpoints(endpoints =>
                endpoints.MapHub<SignalRHandler>("/ws")
            );
        }

        private void UpdateHtmlWithVersion(string[] files, string version, string assetPath)
        {
            foreach (string file in files)
            {
                string path = Path.Combine(
                    assetPath,
                    file
                );

                File.WriteAllText(
                    path,
                    File.ReadAllText(path).Replace("<version>", version)
                );
            }
        }
    }
}
