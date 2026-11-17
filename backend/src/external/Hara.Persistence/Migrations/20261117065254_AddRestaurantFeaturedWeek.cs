using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Hara.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddRestaurantFeaturedWeek : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateOnly>(
                name: "FeaturedFrom",
                table: "Restaurants",
                type: "date",
                nullable: true);

            migrationBuilder.AddColumn<DateOnly>(
                name: "FeaturedUntil",
                table: "Restaurants",
                type: "date",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "FeaturedFrom",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "FeaturedUntil",
                table: "Restaurants");
        }
    }
}
