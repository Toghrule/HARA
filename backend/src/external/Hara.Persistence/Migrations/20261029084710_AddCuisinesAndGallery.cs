using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Hara.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddCuisinesAndGallery : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<List<string>>(
                name: "Cuisines",
                table: "Restaurants",
                type: "text[]",
                nullable: false,
                defaultValueSql: "'{}'");

            migrationBuilder.AddColumn<List<string>>(
                name: "GalleryUrls",
                table: "Restaurants",
                type: "text[]",
                nullable: false,
                defaultValueSql: "'{}'");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Cuisines",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "GalleryUrls",
                table: "Restaurants");
        }
    }
}
