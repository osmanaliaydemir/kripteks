using System.Net;
using System.Text.RegularExpressions;

namespace Kripteks.Core.Helpers;

public static partial class InputSanitizer
{
    /// <summary>
    /// HTML etiketlerini kaldırır ve tehlikeli karakterleri encode eder.
    /// Kullanıcı girdileri veritabanına kaydedilmeden önce çağrılmalıdır.
    /// </summary>
    public static string Sanitize(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
            return string.Empty;

        // HTML etiketlerini kaldır
        var stripped = HtmlTagRegex().Replace(input, string.Empty);

        // Tehlikeli karakterleri encode et
        stripped = WebUtility.HtmlEncode(stripped);

        return stripped.Trim();
    }

    [GeneratedRegex("<[^>]*>", RegexOptions.Compiled)]
    private static partial Regex HtmlTagRegex();
}
