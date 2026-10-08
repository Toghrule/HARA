using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Hara.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddRestaurantChangeRequests : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "RestaurantChangeRequests",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    RestaurantId = table.Column<Guid>(type: "uuid", nullable: false),
                    RequestedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    Address = table.Column<string>(type: "character varying(400)", maxLength: 400, nullable: true),
                    PhoneNumber = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    Description = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: true),
                    DescriptionRu = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: true),
                    DescriptionEn = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: true),
                    DiscountPercent = table.Column<int>(type: "integer", nullable: true),
                    OwnerNote = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    Status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    AdminNote = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    ReviewedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    LastModifiedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RestaurantChangeRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RestaurantChangeRequests_AspNetUsers_RequestedByUserId",
                        column: x => x.RequestedByUserId,
                        principalTable: "AspNetUsers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_RestaurantChangeRequests_Restaurants_RestaurantId",
                        column: x => x.RestaurantId,
                        principalTable: "Restaurants",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_RestaurantChangeRequests_RequestedByUserId",
                table: "RestaurantChangeRequests",
                column: "RequestedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_RestaurantChangeRequests_RestaurantId_Status",
                table: "RestaurantChangeRequests",
                columns: new[] { "RestaurantId", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_RestaurantChangeRequests_Status",
                table: "RestaurantChangeRequests",
                column: "Status");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RestaurantChangeRequests");
        }
    }
}
