# The HARA API as a container image. Build context: the backend folder.
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY Directory.Build.props Hara.sln ./
COPY src ./src
RUN dotnet publish src/ui/Hara.Api/Hara.Api.csproj -c Release -o /app --nologo

FROM mcr.microsoft.com/dotnet/aspnet:9.0
WORKDIR /app
COPY --from=build /app .
ENV ASPNETCORE_URLS=http://+:8080 \
    ASPNETCORE_ENVIRONMENT=Production
EXPOSE 8080
# Secrets (backend/secrets on a PC) are mounted at /app/secrets, uploads live in /app/App_Data.
ENTRYPOINT ["dotnet", "Hara.Api.dll"]
