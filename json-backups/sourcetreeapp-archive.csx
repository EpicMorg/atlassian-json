// Emits the archived SourceTree downloads as JSON on stdout.
//
// Same approach as sourcetreeapp.csx: match the download links and derive everything else from the
// file name. The previous version selected ".wpl tr div>a", a class that no longer exists on the
// page, so it found nothing and wrote out an empty list without failing. The page now uses
// generated class names that change on every rebuild, which is why the download URL is the only
// thing worth matching on.
//
// AngleSharp is gone with it. Parsing the whole document bought nothing over matching the links,
// and the reference was pinned to a years-old alpha.
//
// Exits non-zero when nothing is found, so update.sh can tell breakage from an empty release list.

using System;
using System.Linq;
using System.Net.Http;
using System.Text.Json;
using System.Text.RegularExpressions;

const string PageUrl = "https://www.sourcetreeapp.com/download-archives";

const string UserAgent =
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36";

var downloadLink = new Regex(
    @"href=""(?<url>https://(?:product-)?downloads\.atlassian\.com/software/sourcetree/[^""]+\.(?:dmg|zip|exe|msi))""",
    RegexOptions.IgnoreCase);

var fileName = new Regex(
    @"^(?<product>sourcetree(?:enterprise)?(?:setup)?)[-_](?<version>.+?)\.(?<ext>dmg|zip|exe|msi)$",
    RegexOptions.IgnoreCase);

var client = new HttpClient();
client.DefaultRequestHeaders.UserAgent.ParseAdd(UserAgent);
var page = await client.GetStringAsync(PageUrl).ConfigureAwait(false);

var downloads = downloadLink.Matches(page)
    .Select(match => match.Groups["url"].Value)
    .Distinct(StringComparer.OrdinalIgnoreCase)
    .Select(url => BuildEntry(url, fileName))
    .Where(entry => entry is not null)
    .OrderByDescending(entry => entry.Version, StringComparer.OrdinalIgnoreCase)
    .ToArray();

if (downloads.Length == 0)
{
    Console.Error.WriteLine($"No SourceTree downloads found on {PageUrl}. The page layout has probably changed.");
    Environment.Exit(1);
}

Console.Out.WriteLine(JsonSerializer.Serialize(downloads, new JsonSerializerOptions
{
    WriteIndented = true,
    // camelCase to match the feeds Atlassian publishes for its other products.
    PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
}));

static Entry BuildEntry(string url, Regex fileName)
{
    var name = url[(url.LastIndexOf('/') + 1)..];
    var parsed = fileName.Match(name);
    if (!parsed.Success)
    {
        Console.Error.WriteLine($"Skipping {name}: cannot read a version from it.");
        return null;
    }

    var version = parsed.Groups["version"].Value;
    var extension = parsed.Groups["ext"].Value.ToLowerInvariant();
    var isWindows = extension is "exe" or "msi" || url.Contains("/windows/", StringComparison.OrdinalIgnoreCase);
    var isEnterprise = name.Contains("enterprise", StringComparison.OrdinalIgnoreCase);
    var platform = isWindows ? "Windows" : "Mac";

    return new Entry(
        Description: $"{version} - SourceTree for {platform}",
        Edition: isEnterprise ? "Enterprise" : "Standard",
        ZipUrl: url,
        Version: version,
        Platform: platform,
        // Deliberately null: the page shows no release dates.
        Released: null,
        Type: "Binary");
}

public sealed record Entry(
    string Description,
    string Edition,
    string ZipUrl,
    string Version,
    string Platform,
    string Released,
    string Type);
