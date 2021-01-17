#r "nuget: AngleSharp, 1.0.0-alpha-844"

using System.Linq;

System.Console.Out.WriteLine(
    "download(" + System.Text.Json.JsonSerializer.Serialize(
            new AngleSharp.Html.Parser.HtmlParser()
                .ParseDocument(
                    await new System.Net.Http.HttpClient()
                        .GetStringAsync("https://www.sourcetreeapp.com/download-archives")
                        .ConfigureAwait(false))
            .QuerySelectorAll(".wpl tr div>a")
            .Select(row => new { Version = row.TextContent, ZipUrl = row.GetAttribute("href") })
            .ToArray()) + ")"
);
