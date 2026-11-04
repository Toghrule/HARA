namespace Hara.Application.EmailConfirmation;

/// <summary>The words of the confirmation email, in the language the person's app was in.</summary>
public static class EmailVerificationTexts
{
    public static (string Subject, string Body) For(string? language, string code, int minutes) => language?.ToLowerInvariant() switch
    {
        "en" => (
            $"HARA: your confirmation code {code}",
            $"Your HARA confirmation code is:\n\n{code}\n\nType it in the app. It works for {minutes} minutes.\n\nIf you did not sign up for HARA, ignore this email: nothing will happen."),
        "ru" => (
            $"HARA: ваш код подтверждения {code}",
            $"Ваш код подтверждения HARA:\n\n{code}\n\nВведите его в приложении. Он действует {minutes} минут.\n\nЕсли вы не регистрировались в HARA, просто проигнорируйте это письмо."),
        _ => (
            $"HARA: təsdiq kodunuz {code}",
            $"HARA təsdiq kodunuz:\n\n{code}\n\nOnu tətbiqdə yazın. Kod {minutes} dəqiqə işləyir.\n\nHARA-da qeydiyyatdan keçməmisinizsə, bu məktuba məhəl qoymayın: heç nə olmayacaq.")
    };
}
