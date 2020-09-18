
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using System;
using System.IO;

namespace VirtualGloomhavenBoard
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args)
                .Build()
                .Run()
            ;
        }

        public static IHostBuilder CreateHostBuilder(string[] args)
        {
            string defaultHostUrl = "http://0.0.0.0:5000";
            string appData = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "PurpleKingdomGames",
                "VirtualGloomhavenBoard"
            );

            if (!Directory.Exists(appData))
                Directory.CreateDirectory(appData);

            string appSettings = Path.Combine(appData, "config.json");
            if (!File.Exists(appSettings))
                File.WriteAllText(appSettings, $"{{\r\n\t\"HostUrl\":\"{defaultHostUrl}\"\r\n}}");

            IConfiguration config = new ConfigurationBuilder()
                .SetBasePath(AppDomain.CurrentDomain.BaseDirectory ?? Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json")
                .AddJsonFile(appSettings, true, true)
                .AddCommandLine(args)
                .Build()
            ;

            string hostUrl;
            string configHost = config.GetValue<string>("HostUrl");
            if (!string.IsNullOrEmpty(configHost))
                hostUrl = configHost;
            else
                hostUrl = defaultHostUrl;

            return Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    #if RELEASE
                    webBuilder.UseContentRoot(AppDomain.CurrentDomain.BaseDirectory);
                    #endif
                    webBuilder.UseUrls(hostUrl);
                    webBuilder.UseConfiguration(config);
                    webBuilder.UseStartup<Startup>();
                })
            ;
        }
    }
}
