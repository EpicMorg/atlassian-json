#r "nuget: AngleSharp, 1.0.0-alpha-844"

using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;

const string userAgent = "YourCustomUserAgent/1.0";

var client = new HttpClient();
client.DefaultRequestHeaders.UserAgent.ParseAdd(userAgent);

var source = await client
    .GetStringAsync("https://www.sourcetreeapp.com")
    .ConfigureAwait(false);

var (startText, endText) = ("{ \"type\":\"imkt.components.SourcetreeDownload\"", "</scri");
var startIndex = source.IndexOf(startText, StringComparison.Ordinal);
var endIndex = source.IndexOf(endText, startIndex, StringComparison.Ordinal);
source = source[startIndex..endIndex];

var json = JsonSerializer.Deserialize<Wrap>(source, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
var (a, b, c) = json.Params;
var urls = new[] { a, b, c };

Console.Out.WriteLine(
    "downloads(" +
    JsonSerializer.Serialize(
    urls
        .Select(a => new Uri(a))
        .Select(a => new
        {
            ZipUrl = a.ToString(),
            Version = new[] { "sourcetree", "enterprise", "setup" }
                .Aggregate(Path.GetFileNameWithoutExtension(a.AbsolutePath), (s, ptr) => s.Replace(ptr, "", StringComparison.OrdinalIgnoreCase))
                .TrimStart('-', '_')
        })
        .ToArray()) + ")");

public record Wrap(Params Params);
public record Params(string MacUrl, string WindowsUrl, string EnterpriseUrl);
