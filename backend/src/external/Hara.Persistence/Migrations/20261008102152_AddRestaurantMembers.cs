using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Hara.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddRestaurantMembers : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "OwnerUserId",
                table: "RestaurantSubmissions",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "RestaurantId",
                table: "RestaurantSubmissions",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "RestaurantMembers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    UserId = table.Column<Guid>(type: "uuid", nullable: false),
                    RestaurantId = table.Column<Guid>(type: "uuid", nullable: false),
                    Role = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    FullName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Email = table.Column<string>(type: "character varying(320)", maxLength: 320, nullable: false),
                    PhoneNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    LastModifiedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RestaurantMembers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RestaurantMembers_AspNetUsers_UserId",
                        column: x => x.UserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_RestaurantMembers_Restaurants_RestaurantId",
                        column: x => x.RestaurantId,
                        principalTable: "Restaurants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_RestaurantSubmissions_OwnerUserId",
                table: "RestaurantSubmissions",
                column: "OwnerUserId");

            migrationBuilder.CreateIndex(
                name: "IX_RestaurantSubmissions_RestaurantId",
                table: "RestaurantSubmissions",
                column: "RestaurantId");

            migrationBuilder.CreateIndex(
                name: "IX_RestaurantMembers_RestaurantId_Status",
                table: "RestaurantMembers",
                columns: new[] { "RestaurantId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_RestaurantMembers_UserId",
                table: "RestaurantMembers",
                column: "UserId",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_RestaurantSubmissions_AspNetUsers_OwnerUserId",
                table: "RestaurantSubmissions",
                column: "OwnerUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_RestaurantSubmissions_Restaurants_RestaurantId",
                table: "RestaurantSubmissions",
                column: "RestaurantId",
                principalTable: "Restaurants",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_RestaurantSubmissions_AspNetUsers_OwnerUserId",
                table: "RestaurantSubmissions");

            migrationBuilder.DropForeignKey(
                name: "FK_RestaurantSubmissions_Restaurants_RestaurantId",
                table: "RestaurantSubmissions");

            migrationBuilder.DropTable(
                name: "RestaurantMembers");

            migrationBuilder.DropIndex(
                name: "IX_RestaurantSubmissions_OwnerUserId",
                table: "RestaurantSubmissions");

            migrationBuilder.DropIndex(
                name: "IX_RestaurantSubmissions_RestaurantId",
                table: "RestaurantSubmissions");

            migrationBuilder.DropColumn(
                name: "OwnerUserId",
                table: "RestaurantSubmissions");

            migrationBuilder.DropColumn(
                name: "RestaurantId",
                table: "RestaurantSubmissions");
        }
    }
}
