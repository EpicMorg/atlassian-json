#r "nuget: AngleSharp, 1.0.0-alpha-844"

using System.Linq;
using System.Net.Http;
using AngleSharp.Html.Parser;

string userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:101.0) Gecko/20100101 Firefox/101.0";

var client = new HttpClient();
client.DefaultRequestHeaders.UserAgent.ParseAdd(userAgent);

System.Console.Out.WriteLine(
    "downloads(" + System.Text.Json.JsonSerializer.Serialize(
            new HtmlParser()
                .ParseDocument(
                    await client
                        .GetStringAsync("https://www.sourcetreeapp.com/download-archives")
                        .ConfigureAwait(false))
            .QuerySelectorAll(".wpl tr div>a")
            .Select(row => new { Version = row.TextContent.Trim(), ZipUrl = row.GetAttribute("href") })
            .ToArray()) + ")"
);
