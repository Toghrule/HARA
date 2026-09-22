using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Hara.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddRestaurantCoordinates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "Latitude",
                table: "Restaurants",
                type: "double precision",
                precision: 9,
                scale: 6,
                nullable: false,
                defaultValue: 0.0);

            migrationBuilder.AddColumn<double>(
                name: "Longitude",
                table: "Restaurants",
                type: "double precision",
                precision: 9,
                scale: 6,
                nullable: false,
                defaultValue: 0.0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Latitude",
                table: "Restaurants");

            migrationBuilder.DropColumn(
                name: "Longitude",
                table: "Restaurants");
        }
    }
}
