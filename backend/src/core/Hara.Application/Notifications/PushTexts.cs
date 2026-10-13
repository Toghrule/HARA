namespace Hara.Application.Notifications;

/// <summary>The notification wording in each of the app's three languages (Azerbaijani when unknown).</summary>
internal static class PushTexts
{
    public static PushMessage NewRequest(string language, string token, string phoneNumber, IReadOnlyDictionary<string, string> data)
    {
        var (title, body) = Normalize(language) switch
        {
            "ru" => ("Новая заявка на стол", $"{phoneNumber}. Ответьте в течение 15 минут."),
            "en" => ("New table request", $"{phoneNumber}. Answer within 15 minutes."),
            _ => ("Yeni masa sorğusu", $"{phoneNumber}. 15 dəqiqə ərzində cavab verin.")
        };

        return new PushMessage(token, title, body, data);
    }

    public static PushMessage Answer(string language, string token, bool accepted, string restaurantName, IReadOnlyDictionary<string, string> data)
    {
        var (title, body) = (Normalize(language), accepted) switch
        {
            ("ru", true) => ("Заявка принята", $"{restaurantName} держит стол 30 минут. Покажите код."),
            ("ru", false) => ("Заявка отклонена", $"{restaurantName} не смог принять заявку. Выберите другое место."),
            ("en", true) => ("Request accepted", $"{restaurantName} is holding your table for 30 minutes. Show your code."),
            ("en", false) => ("Request declined", $"{restaurantName} could not accept your request. Try another place."),
            (_, true) => ("Sorğu qəbul edildi", $"{restaurantName} masanı 30 dəqiqə saxlayır. Kodu göstərin."),
            _ => ("Sorğu rədd edildi", $"{restaurantName} sorğunu qəbul edə bilmədi. Başqa məkan seçin.")
        };

        return new PushMessage(token, title, body, data);
    }

    public static string Normalize(string? language) => language?.Trim().ToLowerInvariant() switch
    {
        "ru" => "ru",
        "en" => "en",
        _ => "az"
    };
}
