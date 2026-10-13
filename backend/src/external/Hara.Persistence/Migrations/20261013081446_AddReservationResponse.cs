using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Hara.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationResponse : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "RespondedAt",
                table: "Reservations",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "RespondedByUserId",
                table: "Reservations",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_RespondedByUserId",
                table: "Reservations",
                column: "RespondedByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_AspNetUsers_RespondedByUserId",
                table: "Reservations",
                column: "RespondedByUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_AspNetUsers_RespondedByUserId",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_RespondedByUserId",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "RespondedAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "RespondedByUserId",
                table: "Reservations");
        }
    }
}
