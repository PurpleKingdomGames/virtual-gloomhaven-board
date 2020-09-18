using VirtualGloomhavenBoard.Handlers;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.StaticFiles;

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
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddSignalR();
            services.AddResponseCompression();
            services.AddResponseCaching();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app)
        {
            string? configHost = Configuration.GetValue<string>("HostUrl");
            if (configHost?.ToLower().StartsWith("https://") == true) {
                // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
                app.UseHsts();
                app.UseHttpsRedirection();
            }

            FileExtensionContentTypeProvider contentTypeProvider = new FileExtensionContentTypeProvider();
            contentTypeProvider.Mappings[".scss"] = "text/x-scss";

            FileServerOptions fileOptions = new FileServerOptions();
            fileOptions.StaticFileOptions.ContentTypeProvider = contentTypeProvider;

            app.UseResponseCompression();
            app.UseResponseCaching();
            app.UseFileServer(fileOptions);

            app.UseRouting();
            app.UseEndpoints(endpoints => {
                endpoints.MapHub<SignalRHandler>("/ws");
            });
        }
    }
}
